;; sbcl --script webscraping.lisp   (needs Quicklisp + curl)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload '(:plump :clss :cl-ppcre) :silent t)

(defun fetch (url)
  (plump:parse (uiop:run-program (list "curl" "-sL" "-A" "Mozilla/5.0" url) :output :string)))

(defun text (node)
  "Text of NODE, skipping comments and boilerplate tags; block tags become newlines."
  (let ((tag (and (plump:element-p node) (string-downcase (plump:tag-name node)))))
    (cond ((plump:text-node-p node) (cl-ppcre:regex-replace-all "\\s+" (plump:text node) " "))
          ((member tag '("script" "style" "head" "nav" "header" "footer" "noscript" "iframe")
                   :test #'equal) "")
          ((plump:nesting-node-p node)
           (let ((s (format nil "~{~a~}" (map 'list #'text (plump:children node)))))
             (if (member tag '("p" "div" "li" "br" "tr" "h1" "h2" "h3" "h4" "h5" "h6"
                               "section" "article" "ul" "ol" "pre" "blockquote")
                         :test #'equal)
                 (format nil "~%~a~%" s)
                 s)))
          (t ""))))

(defun clean (s)
  (string-trim '(#\Space #\Newline)
               (cl-ppcre:regex-replace-all "\\n{3,}" (cl-ppcre:regex-replace-all "(?m)^ +| +$" s "")
                                           (format nil "~%~%"))))

(defun headers (url)
  (map 'list (lambda (h) (clean (text h))) (clss:select "h1,h2,h3,h4,h5,h6" (fetch url))))

(defun page-text (url) (clean (text (fetch url))))

(print (headers "https://markwatson.com"))
(format t "~%~%~a~%" (page-text "https://markwatson.com"))
