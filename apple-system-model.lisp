;; sbcl --script apple-system-model.lisp   (macOS on-device Apple Foundation Model via `fm`)
(require :asdf)

(defun apple-fm (prompt)
  (string-trim '(#\Space #\Newline #\Return)
               (uiop:run-program (list "fm" "respond" "--no-stream" prompt) :output :string)))

(print (apple-fm "what is 1 + 10?"))
