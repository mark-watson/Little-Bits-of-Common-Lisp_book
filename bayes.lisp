;; sbcl --script bayes.lisp   (Bayesian inference & medical base-rate fallacy)

(defun bayes-normalize (dist)
  (let ((sum (reduce #'+ dist :key #'cdr)))
    (mapcar (lambda (p) (cons (car p) (/ (cdr p) sum))) dist)))

(defun bayes-update (dist evidence likelihood-fn)
  (bayes-normalize
   (mapcar (lambda (p)
             (cons (car p) (* (cdr p) (funcall likelihood-fn (car p) evidence))))
           dist)))

(defun map-hypothesis (dist)
  (reduce (lambda (a b) (if (> (cdr a) (cdr b)) a b)) dist))

;; Demo: Medical screening base-rate fallacy
;; Disease prevalence: 1%. Test: 95% sensitivity (true +), 5% false +
(let* ((prior '((has-disease . 0.01) (healthy . 0.99)))
       (likelihood (lambda (hyp test-result)
                     (case hyp
                       (has-disease (if (eq test-result '+) 0.95 0.05))
                       (healthy     (if (eq test-result '+) 0.05 0.95)))))
       (post1 (bayes-update prior '+ likelihood))
       (post2 (bayes-update post1 '+ likelihood)))
  (format t "Prior:         ~{~a: ~,4f~^, ~}~%" (mapcan (lambda (p) (list (car p) (cdr p))) prior))
  (format t "After 1st (+): ~{~a: ~,4f~^, ~}  -> MAP: ~a~%"
          (mapcan (lambda (p) (list (car p) (cdr p))) post1) (car (map-hypothesis post1)))
  (format t "After 2nd (+): ~{~a: ~,4f~^, ~}  -> MAP: ~a~%"
          (mapcan (lambda (p) (list (car p) (cdr p))) post2) (car (map-hypothesis post2))))
