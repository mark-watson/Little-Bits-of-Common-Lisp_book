;; sbcl --script ollama.lisp   (needs Quicklisp + local Ollama)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun ollama (prompt &optional (model "qwen3.5:4b"))
  (gethash "response"
           (com.inuoe.jzon:parse
            (uiop:run-program
             (list "curl" "-s" "http://localhost:11434/api/generate" "-d"
                   (format nil "{\"model\":~a,\"prompt\":~a,\"stream\":false,\"think\":false}"
                           (com.inuoe.jzon:stringify model)
                           (com.inuoe.jzon:stringify prompt)))
             :output :string))))

(print (ollama "what is 1 + 10?"))
