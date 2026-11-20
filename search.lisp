;; sbcl --script search.lisp (Exa and Brave Search APIs)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun curl-json (&rest args)
  (com.inuoe.jzon:parse
   (uiop:run-program (list* "curl" "-s" args) :output :string)))

(defun api-key (name)
  (or (uiop:getenv name) (error "~a is not set" name)))

(defun unescape (s)
  "Decode the few HTML entities that show up in search snippets."
  (when s
    (loop for (from . to) in '(("&#x27;" . "'") ("&#39;" . "'")
                               ("&quot;" . "\"") ("&lt;" . "<")
                               ("&gt;" . ">") ("&amp;" . "&"))
          do (loop for i = (search from s)
                     then (search from s :start2 (+ i (length to)))
                   while i
                   do (setf s (concatenate 'string (subseq s 0 i) to
                                           (subseq s (+ i (length from))))))
          finally (return s))))

(defun results (items text-key)
  "List of (title url text) for each hit."
  (map 'list
       (lambda (h)
         (list (unescape (gethash "title" h))
               (gethash "url" h)
               (unescape (gethash text-key h))))
       items))

(defun esearch (query &optional (n 5))
  (results
   (gethash "results"
            (curl-json
             "https://api.exa.ai/search"
             "-H" (format nil "x-api-key: ~a"
                          (api-key "EXA_SEARCH_API_KEY"))
             "-H" "Content-Type: application/json"
             "-d" (format nil
                   (concatenate
                    'string
                    "{\"query\":~a,\"numResults\":~d,"
                    "\"contents\":{\"text\":{\"maxCharacters\":300}}}")
                   (com.inuoe.jzon:stringify query) n)))
   "text"))

(defun bsearch (query &optional (n 5))
  (results
   (gethash
    "results"
    (gethash
     "web"
     (curl-json
      "-G" "https://api.search.brave.com/res/v1/web/search"
      "-H" (format nil "X-Subscription-Token: ~a"
                   (api-key "BRAVE_SEARCH_API_KEY"))
      "-H" "Accept: application/json"
      "--data-urlencode" (format nil "q=~a" query)
      "--data-urlencode" (format nil "count=~d" n)
      "--data-urlencode" "text_decorations=false")))
   "description"))

(print (esearch "Common Lisp SPARQL client" 3))
(print (bsearch "Sedona Arizona hiking" 3))
