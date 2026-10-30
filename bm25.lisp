;; sbcl --script bm25.lisp   (Okapi BM25 document ranking)

(defun tokenize (text)
  (loop with len = (length text) and words = nil and acc = nil
        for i from 0 below len
        for ch = (char text i)
        do (if (alphanumericp ch)
               (push (char-downcase ch) acc)
               (when acc
                 (push (coerce (nreverse acc) 'string) words)
                 (setf acc nil)))
        finally (when acc (push (coerce (nreverse acc) 'string) words))
                (return (nreverse words))))

(defun bm25-search (corpus query &key (k1 1.5) (b 0.75))
  (let* ((docs (mapcar #'tokenize corpus))
         (n (length corpus))
         (lens (mapcar #'length docs))
         (avgdl (/ (reduce #'+ lens) (float (max 1 n))))
         (q-terms (remove-duplicates (tokenize query) :test #'string=)))
    (labels ((idf (term)
               (let ((df (count-if (lambda (d) (member term d :test #'string=)) docs)))
                 (log (+ 1.0 (/ (+ (- n df) 0.5) (+ df 0.5)))))))
      (sort (loop for doc in docs
                  for raw in corpus
                  for len in lens
                  for score = (loop for term in q-terms
                                    for tf = (count term doc :test #'string=)
                                    when (> tf 0)
                                    sum (* (idf term)
                                           (/ (* tf (+ k1 1.0))
                                              (+ tf (* k1 (+ (- 1.0 b) (* b (/ len avgdl))))))))
                  when (> score 0.0)
                  collect (list score raw))
            #'> :key #'car))))

;; Demo: Document corpus search
(let ((corpus '("Common Lisp is a general-purpose programming language with powerful macros."
                "Python is an interpreted language known for data science and machine learning."
                "Deep learning models require automatic differentiation and gradient optimization."
                "Macros in Common Lisp enable syntactic metaprogramming and DSL design."
                "Okapi BM25 is an information retrieval ranking function used in search engines.")))
  (format t "Corpus size: ~a documents~%" (length corpus))
  (dolist (query '("Common Lisp macros" "search ranking" "learning"))
    (format t "~%Query: ~s~%" query)
    (dolist (hit (bm25-search corpus query))
      (format t "  [score: ~5,3f] ~a~%" (first hit) (second hit)))))
