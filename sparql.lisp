;; sbcl --script sparql.lisp   (needs Quicklisp + curl)
#-quicklisp (load "~/quicklisp/setup.lisp")
(ql:quickload :com.inuoe.jzon :silent t)

(defun sparql (endpoint query)
  "Returns a list of rows, each row an alist of (variable . value)."
  (let* ((cmd (list "curl" "-s" "-G" endpoint
                    "-H" "Accept: application/sparql-results+json"
                    "-A" "sparql.lisp/1.0 (Common Lisp example)"
                    "--data-urlencode"
                    (concatenate 'string "query=" query)))
         (raw (uiop:run-program cmd :output :string))
         (json (com.inuoe.jzon:parse raw))
         (bindings (gethash "bindings" (gethash "results" json))))
    (map 'list
         (lambda (row)
           (loop for var being the hash-keys of row
                 using (hash-value b)
                 collect (cons var (gethash "value" b))))
         bindings)))

(defun dbpedia (query)
  (sparql "https://dbpedia.org/sparql" query))

(defun wikidata (query)
  (sparql "https://query.wikidata.org/sparql" query))

(print (dbpedia
        "SELECT ?birth WHERE { dbr:Bill_Gates dbo:birthDate ?birth }"))
(print (wikidata
        (concatenate
         'string
         "SELECT ?label WHERE { "
         "wd:Q5284 rdfs:label ?label FILTER(LANG(?label) = \"en\") }")))
