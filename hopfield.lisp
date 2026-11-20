;; sbcl --script hopfield.lisp (Hopfield associative neural network)

(defun hopfield-train (patterns size)
  (let ((w (make-array (list size size) :initial-element 0)))
    (dolist (p patterns w)
      (dotimes (i size)
        (dotimes (j size)
          (unless (= i j)
            (incf (aref w i j) (* (nth i p) (nth j p)))))))))

(defun hopfield-recall (w input &optional (max-sweeps 10))
  "Update neurons one at a time, in place, until a full sweep changes
nothing. Returns the final state and the number of sweeps used."
  (let ((state (copy-seq input))
        (n (length input)))
    (dotimes (sweep max-sweeps (values state max-sweeps))
      (let ((changed nil))
        (dotimes (i n)
          (let* ((sum (loop for j below n
                            sum (* (aref w i j) (nth j state))))
                 (new (if (>= sum 0) 1 -1)))
            (unless (= new (nth i state))
              (setf (nth i state) new
                    changed t))))
        (unless changed
          (return (values state (1+ sweep))))))))

(defun hopfield-energy (w state)
  (- (* 0.5
        (loop for i below (length state)
              sum (loop for j below (length state)
                        sum (* (aref w i j)
                               (nth i state)
                               (nth j state)))))))

(defun show-pattern (pat &optional (width 4))
  (loop for i from 0 below (length pat)
        do (format t "~a " (if (= (nth i pat) 1) "#" "."))
        when (zerop (mod (1+ i) width)) do (terpri)))

;; Demo: Train on 16-bit 'X' and 'O' patterns, recall corrupted pattern
(let* ((pattern-x '( 1 -1 -1  1
                    -1  1  1 -1
                    -1  1  1 -1
                     1 -1 -1  1))
       (pattern-o '( 1  1  1  1
                     1 -1 -1  1
                     1 -1 -1  1
                     1  1  1  1))
       (w (hopfield-train (list pattern-x pattern-o) 16))
       ;; Corrupt pattern-x by flipping 3 bits (indices 0, 5, 10)
       (noisy (let ((cp (copy-seq pattern-x)))
                (dolist (idx '(0 5 10) cp)
                  (setf (nth idx cp) (- (nth idx cp)))))))
  (format t "Original Pattern 'X' (Energy: ~,1f):~%"
          (hopfield-energy w pattern-x))
  (show-pattern pattern-x)
  (format t "~%Noisy Pattern with 3 bit-flips (Energy: ~,1f):~%"
          (hopfield-energy w noisy))
  (show-pattern noisy)
  (multiple-value-bind (recalled sweeps) (hopfield-recall w noisy)
    (format t "~%Recalled Associative Memory (Energy: ~,1f):~%"
            (hopfield-energy w recalled))
    (show-pattern recalled)
    (format t "~%Recovered perfectly? ~a (stable after ~d sweeps)~%"
            (equal recalled pattern-x) sweeps)))
