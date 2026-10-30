;; sbcl --script triple-store.lisp (in-memory RDF triple store)

(defvar *store* nil)

(defun add-triple (s p o &optional (store-var '*store*))
  (push (list s p o) (symbol-value store-var)))

(defun var-p (x)
  (and (symbolp x) (char= (char (symbol-name x) 0) #\?)))

(defun match-triple (pat triple env)
  (loop for p in pat for x in triple
        do (cond ((eq env :fail) (return :fail))
                 ((var-p p)
                  (let ((b (assoc p env)))
                    (if b (unless (equal (cdr b) x) (return :fail))
                        (push (cons p x) env))))
                 ((not (equal p x)) (return :fail)))
        finally (return env)))

(defun query-triples (patterns &optional (store *store*) (envs '(())))
  (if (null patterns) envs
      (query-triples
       (cdr patterns) store
       (loop for env in envs
             append
             (loop for tr in store
                   for next-env = (match-triple (car patterns)
                                                tr
                                                (copy-alist env))
                   unless (eq next-env :fail) collect next-env)))))

;; Demo: Knowledge graph of thinkers, occupations, and cities
(dolist (tr '((socrates :is-a :philosopher)
              (socrates :lives-in :athens)
              (plato    :is-a :philosopher)
              (plato    :lives-in :athens)
              (descartes :is-a :philosopher)
              (descartes :lives-in :paris)
              (monet    :is-a :painter)
              (monet    :lives-in :paris)
              (voltaire :is-a :writer)
              (voltaire :lives-in :paris)))
  (apply #'add-triple tr))

(format t "Knowledge base triples count: ~a~%" (length *store*))

(format t "~%Query 1: Who is a philosopher?~%")
(dolist (b (query-triples '((?who :is-a :philosopher))))
  (format t "  who: ~a~%" (cdr (assoc '?who b))))

(format t "~%Query 2: Who lives in Paris AND is a philosopher? ~
           (relational join)~%")
(dolist (b (query-triples '((?who :lives-in :paris)
                            (?who :is-a :philosopher))))
  (format t "  who: ~a~%" (cdr (assoc '?who b))))

(format t "~%Query 3: All people in Paris and their occupations:~%")
(dolist (b (query-triples '((?person :lives-in :paris)
                            (?person :is-a ?job))))
  (format t "  ~a is a ~a in Paris~%"
          (cdr (assoc '?person b))
          (cdr (assoc '?job b))))
