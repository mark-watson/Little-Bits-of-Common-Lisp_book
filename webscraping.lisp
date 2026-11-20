;; sbcl --script webscraping.lisp   (needs Quicklisp + curl)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload '(:plump :clss :cl-ppcre) :silent t)

(defun fetch (url)
  (plump:parse
   (uiop:run-program
    (list "curl" "-fsL" "-A" "Mozilla/5.0" url) :output :string)))

(defun text (node)
  "Text of NODE, skipping boilerplate; block tags become newlines."
  (let ((tag (and (plump:element-p node)
                  (string-downcase (plump:tag-name node)))))
    (cond ((plump:text-node-p node)
           (cl-ppcre:regex-replace-all "\\s+" (plump:text node) " "))
          ((member tag
                   '("script" "style" "head" "nav" "header"
                     "footer" "noscript" "iframe")
                   :test #'equal)
           "")
          ((plump:nesting-node-p node)
           (let ((s (format nil "~{~a~}"
                            (map 'list #'text (plump:children node)))))
             (if (member tag '("p" "div" "li" "br" "tr" "h1" "h2"
                               "h3" "h4" "h5" "h6" "section"
                               "article" "ul" "ol" "pre" "blockquote")
                          :test #'equal)
                 (format nil "~%~a~%" s)
                 s)))
          (t ""))))

(defun clean (s)
  (string-trim
   '(#\Space #\Newline)
   (cl-ppcre:regex-replace-all
    "\\n{3,}"
    (cl-ppcre:regex-replace-all "(?m)^ +| +$" s "")
    (format nil "~%~%"))))

(defun dom (page)
  "PAGE is either a URL string or an already-parsed plump DOM."
  (if (stringp page) (fetch page) page))

(defun headers (page)
  (map 'list (lambda (h) (clean (text h)))
       (clss:select "h1,h2,h3,h4,h5,h6" (dom page))))

(defun page-text (page) (clean (text (dom page))))

(let ((root (fetch "https://markwatson.com")))
  (print (headers root))
  (format t "~%~%~a~%" (page-text root)))
