;; sbcl --script gemini.lisp   (needs Quicklisp + GOOGLE_API_KEY)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun gemini (prompt &optional (model "gemini-3.5-flash-lite"))
  (let* ((base
          "https://generativelanguage.googleapis.com/v1beta/models/")
         (url (format nil "~a~a:generateContent" base model))
         (key (uiop:getenv "GOOGLE_API_KEY"))
         (body (format nil
                       "{\"contents\":[{\"parts\":[{\"text\":~a}]}]}"
                       (com.inuoe.jzon:stringify prompt)))
         (j (com.inuoe.jzon:parse
             (uiop:run-program
              (list "curl" "-s" url
                    "-H" "Content-Type: application/json"
                    "-H" (format nil "x-goog-api-key: ~a" key)
                    "-d" body)
              :output :string))))
    (gethash "text"
             (aref (gethash "parts"
                            (gethash "content"
                                     (aref (gethash "candidates" j) 0)))
                   0))))

(print (gemini "what is 1 + 10?"))
