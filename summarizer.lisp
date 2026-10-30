;; sbcl --script summarizer.lisp (extractive text summarization)

(defparameter *stop-words*
  '("the" "a" "an" "in" "on" "at" "to" "for" "of" "and" "or" "is"
    "are" "was" "were" "it" "that" "this" "with" "as" "by" "from"
    "be" "has" "have" "its"))

(defun words (text)
  (loop with len = (length text) and acc = nil and res = nil
        for i from 0 below len
        for ch = (char text i)
        do (if (alphanumericp ch)
               (push (char-downcase ch) acc)
               (when acc
                 (push (coerce (nreverse acc) 'string) res)
                 (setf acc nil)))
        finally (when acc (push (coerce (nreverse acc) 'string) res))
                (return (nreverse res))))

(defun split-sentences (text)
  (loop with len = (length text) and start = 0 and res = nil
        for i from 0 below len
        for ch = (char text i)
        when (member ch '(#\. #\! #\?))
          do (let ((s (string-trim '(#\Space #\Tab #\Newline #\Return)
                                   (subseq text start (1+ i)))))
               (when (> (length s) 0) (push s res))
               (setf start (1+ i)))
        finally (let ((s (string-trim
                          '(#\Space #\Tab #\Newline #\Return)
                          (subseq text start len))))
                  (when (> (length s) 0) (push s res)))
                (return (nreverse res))))

(defun summarize (text &optional (n 2))
  (let* ((sentences (split-sentences text))
         (freqs (make-hash-table :test 'equal)))
    (dolist (s sentences)
      (dolist (w (words s))
        (unless (member w *stop-words* :test #'string=)
          (incf (gethash w freqs 0)))))
    (let ((scored
            (loop for s in sentences for idx from 0
                  for ws = (words s)
                  for score = (if (null ws) 0.0
                                  (/ (loop for w in ws
                                           sum (gethash w freqs 0))
                                     (float (length ws))))
                  collect (list score idx s))))
      (mapcar #'third
              (sort (subseq (sort scored #'> :key #'first)
                            0 (min n (length scored)))
                    #'< :key #'second)))))

;; Demo: Multi-sentence paragraph extraction
(let* ((text
        (concatenate
         'string
         "Common Lisp is an expressive, multi-paradigm programming "
         "language with a rich history in artificial intelligence. "
         "It features dynamic typing, an advanced object system, "
         "and syntactic macros that allow programmers to create "
         "domain-specific languages. "
         "Extractive summarization algorithms score sentences based "
         "on significant word frequencies across a document. "
         "In this example, we calculate term frequencies and rank "
         "sentences to produce a concise summary. "
         "Common Lisp continues to empower developers to build "
         "complex symbolic and numerical systems with high "
         "productivity."))
       (summary (summarize text 2)))
  (format t "Original text: ~a sentences.~%~%"
          (length (split-sentences text)))
  (format t "Extractive 2-Sentence Summary:~%")
  (dolist (s summary)
    (format t "  • ~a~%" s)))
