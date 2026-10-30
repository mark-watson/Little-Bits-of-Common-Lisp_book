;; sbcl --script vector-store.lisp (in-memory dense vector store)

(defun v-dot (a b)
  (loop for x across a for y across b sum (* x y)))

(defun v-norm (a)
  (sqrt (v-dot a a)))

(defun v-cosine (a b)
  (let ((na (v-norm a)) (nb (v-norm b)))
    (if (or (zerop na) (zerop nb)) 0.0 (/ (v-dot a b) (* na nb)))))

(defun make-vector-store ()
  (make-hash-table :test 'equal))

(defun store-add (store id text vec)
  (setf (gethash id store) (list text (coerce vec 'vector))))

(defun store-search (store query-vec &optional (k 3))
  (let ((qv (coerce query-vec 'vector)))
    (subseq
     (sort (loop for id being the hash-keys of store
                   using (hash-value item)
                 for score = (v-cosine qv (second item))
                 collect (list score id (first item)))
           #'> :key #'car)
     0 (min k (hash-table-count store)))))

;; Demo: Semantic vector search in 4D concept space
(let ((store (make-vector-store)))
  (store-add store "item-1" "queen"    #(0.90 0.90 0.05 0.10))
  (store-add store "item-2" "king"     #(0.95 0.10 0.05 0.10))
  (store-add store "item-3" "princess" #(0.80 0.95 0.05 0.15))
  (store-add store "item-4" "apple"    #(0.05 0.10 0.95 0.30))
  (store-add store "item-5" "banana"   #(0.05 0.10 0.90 0.95))

  (format t "Vector Store Entries: ~a~%" (hash-table-count store))

  (format t "~%Query 1: Royal female concept #(0.85 0.85 0.05 0.10)~%")
  (dolist (hit (store-search store #(0.85 0.85 0.05 0.10) 3))
    (format t "  [sim: ~5,3f] (~a) ~s~%"
            (first hit) (second hit) (third hit)))

  (format t "~%Query 2: Sweet fruit concept #(0.05 0.10 0.85 0.90)~%")
  (dolist (hit (store-search store #(0.05 0.10 0.85 0.90) 3))
    (format t "  [sim: ~5,3f] (~a) ~s~%"
            (first hit) (second hit) (third hit))))
