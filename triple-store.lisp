;; sbcl --script triple-store.lisp (in-memory RDF triple store)

;; A store is a list of (subject predicate object) triples.
;; To keep several stores, rebind it: (let ((*store* nil)) ...)
(defvar *store* nil)

(defun add-triple (s p o)
  (push (list s p o) *store*))

(defun var-p (x)
  (and (symbolp x) (char= (char (symbol-name x) 0) #\?)))

(defun match-triple (pat triple env)
  "ENV extended so that PAT matches TRIPLE, or :FAIL."
  (loop for p in pat for x in triple
        do (cond ((var-p p)
                  (let ((b (assoc p env)))
                    (cond ((null b) (push (cons p x) env))
                          ((not (equal (cdr b) x)) (return :fail)))))
                 ((not (equal p x)) (return :fail)))
        finally (return env)))

(defun query-triples (patterns &optional (store *store*) (envs '(())))
  (if (null patterns) envs
      (query-triples
       (cdr patterns) store
       (loop for env in envs
             append
             (loop for tr in store
                   for next-env = (match-triple (car patterns) tr env)
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
