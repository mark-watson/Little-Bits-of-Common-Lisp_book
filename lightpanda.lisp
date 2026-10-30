;; sbcl --script lightpanda.lisp   (needs the lightpanda binary on PATH)
(require :asdf)

(defun lightpanda (url &optional (dump "html"))
  "DUMP is one of: html, markdown, semantic_tree, semantic_tree_text."
  (uiop:run-program (list "lightpanda" "fetch" "--dump" dump "--log_level" "warn" url)
                    :output :string))

(defun links (html)
  (loop for i = (search "href=\"" html) then (search "href=\"" html :start2 end)
        for end = (and i (position #\" html :start (+ i 6)))
        while end collect (subseq html (+ i 6) end)))

(print (lightpanda "https://markwatson.com/" "markdown"))
(print (links (lightpanda "https://markwatson.com/")))
