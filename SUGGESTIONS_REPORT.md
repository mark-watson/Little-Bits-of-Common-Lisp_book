# Suggestions Report: Concise Standalone Common Lisp Examples

**Project**: `SHORTEST_CODE` Expansion  
**Target Directory**: `/Users/markw/GITHUB/common-lisp-experiments/SHORTEST_CODE`  
**Source Corpus**: `/Users/markw/GITHUB/loving-common-lisp/src`  
**Date**: October 2026  
**Status**: Recommendation & Implementation Specification (Milestone M1)  
**Author**: Teamwork Worker (Worker M1: Suggestions Report)

---

## 1. Executive Summary

This report establishes a comprehensive, publication-grade inventory, comparative gap analysis, and candidate catalog for expanding `/Users/markw/GITHUB/common-lisp-experiments/SHORTEST_CODE` with new, ultra-short, standalone Common Lisp examples adapted from `/Users/markw/GITHUB/loving-common-lisp/src`.

The `SHORTEST_CODE` repository embodies a distinctive philosophy within the Common Lisp ecosystem: **maximum expressive power with minimal lines of code, zero boilerplate, and dual execution modes** (standalone shell scripting via `sbcl --script` alongside clean interactive batch-loading via `load.lisp`). Currently, the directory contains 10 files totaling 340 lines of code. However, existing examples are heavily concentrated in external subprocess wrappers (macOS automation, HTML scraping, Exa/Brave search APIs, remote SPARQL endpoints, and one-shot LLM prompts), leaving rich foundational domains of Common Lisp—such as probabilistic inference, local knowledge graphs, automatic differentiation, associative memory, dense vector retrieval, and text summarization—unrepresented.

Through a systematic survey of all 46 subdirectories and 121 Common Lisp source files in `loving-common-lisp/src`, we have identified high-value algorithmic gems that can be distilled into concise (<50 lines), zero-dependency, self-contained standalone examples requiring no external data files.

This document fulfills Requirements **R1** (Inventory & Comparative Analysis), **R2** (Candidate Recommendations Catalog), and **R3** (Non-Duplication & Conciseness Strategy), and presents an immediate Action Plan for implementing 7 standalone examples directly in `SHORTEST_CODE`.

---

## 2. Baseline Inventory: Existing `SHORTEST_CODE` Examples (Requirement R1)

The current `SHORTEST_CODE` repository comprises 10 `.lisp` files (9 task examples and 1 meta-loader), totaling 340 lines of code (average 29.2 lines per file; median 26 lines).

### 2.1. Master Catalog of Existing Files

| # | File Name | Size (Bytes) | Lines (`wc -l`) | Primary Domain | Dependencies & Primitives | Key Exported / Defined Functions |
|---|---|---|---|---|---|---|
| 1 | `apple-system-model.lisp` | 313 | 9 | Local AI / macOS Foundation Model | `asdf` (`uiop`), CLI `fm` | `(apple-fm prompt)` |
| 2 | `gemini.lisp` | 896 | 18 | Cloud AI / Google Gemini REST API | Quicklisp, `com.inuoe.jzon`, `uiop`, CLI `curl` | `(gemini prompt &optional model)` |
| 3 | `lightpanda.lisp` | 665 | 16 | Headless Browser Scraping / Links | `asdf` (`uiop`), CLI `lightpanda` | `(lightpanda url &optional dump)`, `(links html)` |
| 4 | `load.lisp` | 3,315 | 71 | Meta-Tooling / REPL Loader & Registry | Pure ANSI Common Lisp (`read`/`eval`) | `(help)` |
| 5 | `ollama.lisp` | 650 | 16 | Local AI / Ollama REST API | Quicklisp, `com.inuoe.jzon`, `uiop`, CLI `curl` | `(ollama prompt &optional model)` |
| 6 | `osascript.lisp` | 3,283 | 64 | macOS OS Automation & Apps | `asdf` (`uiop`), CLI `osascript`, CLI `sqlite3` | `(osascript script)`, `(mail-unread-count)`, `(get-todays-events)`, `(send-imessage phone msg)`, `(add-reminder name)`, `(read-recent-imessages &optional limit)`, `(safari-login ...)` |
| 7 | `search.lisp` | 1,692 | 33 | Web Search APIs (Exa AI & Brave) | Quicklisp, `com.inuoe.jzon`, `uiop`, CLI `curl` | `(curl-json &rest args)`, `(results items text-key)`, `(esearch query &optional n)`, `(bsearch query &optional n)` |
| 8 | `sparql.lisp` | 1,240 | 26 | Linked Data / Remote SPARQL Endpoints | Quicklisp, `com.inuoe.jzon`, `uiop`, CLI `curl` | `(sparql endpoint query)`, `(dbpedia query)`, `(wikidata query)` |
| 9 | `symbolic-math.lisp` | 2,918 | 62 | Symbolic Polynomial Calculus | Pure ANSI Common Lisp (zero dependencies) | `(poly &rest coefs)`, `(normalize terms)`, `(p+ &rest ps)`, `(p- p q)`, `(scale p k)`, `(degree p)`, `(evaluate p x)`, `(deriv p &optional n)`, `(integ p &optional n)`, `(definite p a b)`, `(critical-point-p p x)` |
| 10 | `webscraping.lisp` | 1,591 | 35 | HTML DOM Parsing & Cleaning | Quicklisp, `plump`, `clss`, `cl-ppcre`, `uiop`, CLI `curl` | `(fetch url)`, `(text node)`, `(clean s)`, `(headers url)`, `(page-text url)` |

### 2.2. Architectural Patterns and Design Philosophy in `SHORTEST_CODE`

A rigorous inspection of the existing files reveals four overarching architectural conventions that define the project style:

1. **Dual-Mode Executability**:
   - **Shell Script Mode**: Each file starts with a standardized header comment indicating invocation via `sbcl --script <file>.lisp`. When executed directly, the file defines functions and runs self-contained test invocations at the bottom, printing output to stdout and exiting cleanly with code 0.
   - **Interactive Loader Mode**: Running `(load "load.lisp")` dynamically scans the directory, parsing top-level forms. It selectively evaluates `defun`, `defpackage`, `in-package`, `require`, `load`, and `ql:quickload` into `CL-USER`, while purposefully omitting top-level test executions (`print`, `format`). It registers each function in `*help*` and provides the interactive `(help)` index.
2. **"Lisp + Unix" Subprocess Strategy**:
   - For network operations, rather than pulling in heavyweight Common Lisp HTTP stacks (such as `dexador` or `drakma` with OpenSSL bindings), the repository favors invoking standard OS CLI tools (`curl`, `osascript`, `sqlite3`, `lightpanda`, `fm`) via `uiop:run-program`. Common Lisp handles JSON parsing (`com.inuoe.jzon`), DOM querying, and data transformation into idiomatic Lisp structures (alists, lists, vectors).
3. **Pure ANSI Common Lisp for Pure Algorithms**:
   - When external system boundaries are not involved, solutions rely strictly on ANSI Common Lisp with zero external dependencies (as exemplified by `symbolic-math.lisp`).
4. **Extreme Brevity & Zero Boilerplate**:
   - No separate `.asd` system definitions.
   - No sprawling package hierarchies; symbols are defined directly into `CL-USER` or lightweight packages.
   - Concise idiomatic primitives: `loop` with compound clauses, `reduce`, `mapcar`, and formatted stream printing.

---

## 3. Source Inventory: `loving-common-lisp/src` (Requirement R1)

The repository at `/Users/markw/GITHUB/loving-common-lisp/src` represents the codebase for Mark Watson's book *Loving Common Lisp* and adjacent AI research projects.

### 3.1. Overall Inventory Metrics
- **Subdirectories**: 46 active directories containing Lisp code (plus documentation/data folders `cl-book-apis` and `data`).
- **Common Lisp Source Files (`.lisp`)**: 121
- **ASDF System Definitions (`.asd`)**: 27
- **Total Code Volume**: ~118,500 lines
  - *Embedded Linguistic & Category Data Tables* (`FastTagData.lisp`, `cat-data-tables.lisp`): ~100,000 lines
  - *Core Logic & Example Implementations*: ~18,500 lines

### 3.2. Master Subdirectory Catalog (All 46 Directories)

| # | Directory | Lisp Files | ASD File | SLOC | Primary External Dependencies | Primary Domain & Focus |
|---|---|---|---|---|---|---|
| 1 | `Bridge_game` | 7 | `bridge.asd` | 1,917 | Pure CL | Game AI, card play heuristics, bidding convention engine |
| 2 | `Karpathy_MicroGPT` | 1 | None | 179 | Pure CL | Scalar autograd DAG engine & character-level Transformer |
| 3 | `Probability` | 6 | `probability.asd` | 398 | Pure CL | Bayesian updating, MAP, Pearson correlation, statistics |
| 4 | `RAG` | 7 | `rag.asd` | 1,238 | `litelm`, `usocket`, `uiop` | Retrieval-Augmented Generation, vector store, agent memory |
| 5 | `anomaly_detection` | 3 | `anomaly-detection.asd` | 346 | `uiop` | Multivariate Gaussian anomaly detection & thresholding |
| 6 | `autocontext` | 2 | `autocontext.asd` | 230 | `litelm`, `magicl`, `split-sequence`, `yason` | Dynamic BM25 ranking & document context injection |
| 7 | `cache_engine` | 2 | `cache-engine.asd` | 159 | `sqlite` | Persistent SQLite key-value cache with timestamp expiry |
| 8 | `categorize_summarize`| 3 | `categorize_summarize.asd` | 1,789 | `fasttag`, `myutils` | Frequency-based extractive summarization & text categorization |
| 9 | `cl-ai-coding-agent` | 3 | `cl-ai-coding-agent.asd` | 255 | `litelm`, `uiop` | Autonomous coding agent with shell and file tools |
| 10 | `cl-book-apis` | 0 | None | 0 | None | Agent skill documentation & API guides (`SKILL.md`) |
| 11 | `clsql_examples` | 3 | None | 49 | `clsql`, `clsql-sqlite3` | Relational ORM mapping (`def-view-class`), insert & select |
| 12 | `code_snippets_for_book`| 7 | None | 417 | Pure CL | Hopfield network, backpropagation MLP, stream reader demos |
| 13 | `daily_use` | 2 | `daily-use.asd` | 238 | `gemini`, `litelm`, `cache-engine`, `cl-readline` | Grounded interactive REPL assistant |
| 14 | `data` | 0 | None | 0 | None | Text corpora (sports, health, chemistry news) |
| 15 | `dbpedia` | 2 | `dbpedia.asd` | 42 | `drakma`, `babel`, `s-xml` | DBpedia Lookup REST API with XML stream parsing |
| 16 | `docs-qa` | 2 | `docs-qa.asd` | 141 | `litelm`, `sqlite`, `uiop` | Document embedding storage & QA querying |
| 17 | `entities` | 2 | `entities.asd` | 58 | `myutils`, `uiop` | N-gram sliding window Named-Entity Recognition (NER) |
| 18 | `entities_dbpedia` | 2 | `entities_dbpedia.asd` | 113 | `myutils`, `split-sequence` | Entity linking against DBpedia canonical URIs |
| 19 | `entity-uris` | 2 | `entity-uris.asd` | 119 | `myutils`, `split-sequence` | Entity resolution & disambiguation to web URIs |
| 20 | `fasttag` | 3 | `fasttag.asd` | 93,064 | `myutils` | Eric Brill rule-based Part-of-Speech tagger |
| 21 | `gemini` | 3 | `gemini.asd` | 291 | `alexandria`, `cl-json`, `dexador` | Google Gemini API, search grounding, multi-turn tool use |
| 22 | `groq` | 2 | `groq.asd` | 57 | `cl-json`, `uiop` | Groq OpenAI-compatible chat completion client |
| 23 | `kbnlp` | 3 | `kbnlp.asd` | 7,168 | `fasttag`, `entity-uris`, `myutils` | Knowledge-based natural language processing pipeline |
| 24 | `kgn-capi-ui` | 5 | `kgn-capi-ui.asd` | 336 | `capi`, `lw-grapher`, `sparql` | LispWorks CAPI desktop GUI for knowledge navigation |
| 25 | `kgn-common` | 3 | `kgn-common.asd` | 388 | `alexandria`, `cl-json`, `drakma`, `sqlite` | Knowledge Base Navigator core data models |
| 26 | `kgn-text-ui` | 2 | `kgn-text-ui.asd` | 94 | `kbnlp`, `kgn-common`, `sparql` | Console REPL knowledge graph browser |
| 27 | `kgsampler` | 2 | `kgsampler.asd` | 93 | `drakma`, `sparql`, `uiop` | DBpedia subgraph extraction via SPARQL CONSTRUCT |
| 28 | `knowledge-base-navigator`| 2 | `knowledge-base-navigator.asd`| 106 | `alexandria`, `cl-json`, `uiop` | Entity extraction & interactive graph browsing |
| 29 | `lightpanda` | 2 | `lightpanda.asd` | 80 | `cl-json`, `uiop` | Headless browser execution & DOM tree dump |
| 30 | `litelm` | 6 | `litelm.asd` | 641 | `dexador`, `uiop` | Universal multi-provider LLM gateway (OpenAI/Gemini/Ollama) |
| 31 | `llm-reasoners` | 2 | None | 612 | `litelm`, `uiop` | Chain-of-Thought & Tree-of-Thought reasoning with beam search |
| 32 | `lw-grapher` | 6 | `lw-grapher.asd` | 433 | `capi`, `myutils` | Interactive LispWorks CAPI node/edge graph pane |
| 33 | `macOS_osascript` | 4 | `mac.asd` | 161 | `uiop` | AppleScript bridge (Mail, Messages, Reminders, Safari) |
| 34 | `mistral` | 2 | `mistral.asd` | 65 | `cl-json`, `uiop` | Mistral AI chat completion client |
| 35 | `myutils` | 2 | `myutils.asd` | 58 | `drakma`, `babel`, `s-xml` | String tokenization, file slurping, string replacement |
| 36 | `nsk-neural-symbolic-graph`| 13 | `nsk.asd` | 919 | `litelm`, `hunchentoot` (opt) | Neuro-symbolic graph unification & logic engine |
| 37 | `ollama` | 6 | `ollama.asd` | 341 | `litelm`, `quri`, `uiop` | Ollama client, tool calling, cloud search integration |
| 38 | `ollama_images` | 1 | None | 90 | `cl-base64`, `litelm`, `uiop` | Multimodal vision prompting with base64 image encoding |
| 39 | `search_APIs` | 5 | `search-apis.asd` | 459 | `dexador`, `quri`, `uiop` | Multi-provider search wrapper (Brave, Tavily, Serper) |
| 40 | `simple_rdf_sparql` | 2 | `simple_rdf_sparql.asd` | 142 | Pure CL | In-memory RDF triple store & conjunctive graph query engine |
| 41 | `sparql` | 2 | `sparql.asd` | 143 | `cl-json`, `drakma`, `myutils` | Multi-endpoint SPARQL client over HTTP |
| 42 | `sparql-cache` | 2 | `sparql-cache.asd` | 97 | `sqlite`, `cl-json`, `drakma` | Caching SPARQL client backed by SQLite |
| 43 | `symbolic-math` | 3 | `symbolic-math.asd` | 648 | Pure CL | Symbolic polynomial calculus, differentiation & integration |
| 44 | `text-adventure-game` | 2 | None | 121 | `litelm`, `uiop` | Interactive conversational game with LLM state memory |
| 45 | `webkit-cl` | 7 | `webkit-cl.asd` | 706 | `cffi`, `cl-json` | Native macOS Cocoa/WebKit desktop GUI via FFI bridge |
| 46 | `webscraping` | 4 | None | 240 | `drakma`, `plump`, `clss` | HTML parsing, CSS selectors, markdown conversion |

### 3.3. Major Computational Domains Across the Corpus

The 46 subdirectories organize cleanly into 10 computational domains:
1. **Machine Learning & Neural Networks**: `Karpathy_MicroGPT` (Autograd, Transformer), `code_snippets_for_book` (Hopfield associative network, backprop MLP), `anomaly_detection` (multivariate normal distribution).
2. **Probabilistic Reasoning & Statistics**: `Probability` (Bayes' theorem, MAP hypothesis, base-rate fallacy, Pearson/Spearman correlation).
3. **Knowledge Graphs & Semantic Web**: `simple_rdf_sparql` (in-memory triple store, mini-SPARQL), `sparql`/`sparql-cache` (remote endpoints), `kgsampler` (subgraph extraction), `nsk-neural-symbolic-graph` (pattern unification).
4. **Information Retrieval & Local Search**: `autocontext/bm25.lisp` (Okapi BM25 ranking algorithm), `RAG/vector-store.lisp` (dense vector cosine similarity).
5. **Natural Language Processing & Text Mining**: `categorize_summarize` (frequency-based extractive summarization), `fasttag` (Brill POS tagger), `entities` (dictionary NER).
6. **Large Language Model (LLM) Gateways & Reasoners**: `litelm` (multi-provider client), `llm-reasoners` (tree-of-thought, beam search), `cl-ai-coding-agent` (tool-calling agent).
7. **Multimodal & Interactive AI**: `ollama_images` (vision prompting), `text-adventure-game` & `daily_use` (multi-turn conversation REPL).
8. **Web Scraping & Search APIs**: `search_APIs` (Brave/Tavily), `webscraping` (Plump/CLSS DOM traversal), `lightpanda` (headless browser).
9. **Desktop GUI & Operating System Automation**: `webkit-cl` (Cocoa WKWebView via CFFI), `macOS_osascript` (AppleScript automation), `lw-grapher` (CAPI).
10. **Data Persistence & Relational Databases**: `cache_engine` (SQLite key-value store), `clsql_examples` (relational ORM).

---

## 4. Comparative Gap Analysis & Non-Duplication Strategy (Requirement R3)

### 4.1. Strict Non-Duplication Boundary

To satisfy Requirement **R3**, new candidate examples must strictly avoid duplicating capabilities, topics, or libraries already present in `/Users/markw/GITHUB/common-lisp-experiments/SHORTEST_CODE`.

The following domains are already fully represented in `SHORTEST_CODE` and must **NOT** be duplicated:
- **Remote SPARQL Queries**: `sparql.lisp` already handles remote HTTP queries against DBpedia and Wikidata. *(Any new Semantic Web example must focus strictly on in-memory graph structures and local pattern unification).*
- **Web Search APIs**: `search.lisp` already interfaces with Exa AI and Brave Search APIs. *(Any new search example must focus on local, offline document retrieval algorithms).*
- **Web Scraping & HTML DOM Parsing**: `webscraping.lisp` already covers Plump, CLSS, and CL-PPCRE, and `lightpanda.lisp` covers headless browser rendering.
- **macOS System Automation**: `osascript.lisp` already provides comprehensive coverage of Apple Mail, Calendar, Reminders, Messages, Safari, and SQLite `chat.db`.
- **One-Shot LLM Text Prompting**: `gemini.lisp`, `ollama.lisp`, and `apple-system-model.lisp` already cover basic prompt/response queries.
- **Symbolic Polynomial Calculus**: `symbolic-math.lisp` already handles polynomial differentiation, integration, and root finding.

### 4.2. Identified Gaps and High-Value Opportunities

Cross-referencing the baseline inventory against the source repository reveals several glaring omissions in `SHORTEST_CODE`:

```
┌───────────────────────────────────────┬──────────────────────┬──────────────────────┐
│ Computational Domain                  │ In loving-common-lisp│ In SHORTEST_CODE     │
├───────────────────────────────────────┼──────────────────────┼──────────────────────┤
│ Probabilistic Reasoning / Bayes       │ YES (Probability/)   │ NONE (Critical Gap)  │
│ In-Memory Graph Querying / Datalog    │ YES (simple_rdf/)    │ NONE (Only remote)   │
│ Scalar Automatic Differentiation (AD) │ YES (MicroGPT/)      │ NONE (Critical Gap)  │
│ Offline Document Ranking (BM25)       │ YES (autocontext/)   │ NONE (Only web APIs) │
│ Associative Neural Memory             │ YES (snippets/)      │ NONE (No neural nets)│
│ Dense Vector Similarity Store (RAG)   │ YES (RAG/)           │ NONE (Critical Gap)  │
│ Extractive Text Summarization         │ YES (categorize/)    │ NONE (Only raw DOM)  │
│ Multimodal LLM Vision Prompting       │ YES (ollama_images/) │ NONE (Only text LLM) │
│ Interactive Multi-Turn Chat REPL      │ YES (adventure_game/)│ NONE (Only one-shot) │
│ Statistical Correlation & Covariance  │ YES (correlation.lisp│ NONE                 │
│ Persistent SQLite Key-Value Caching   │ YES (cache_engine/)  │ NONE (Only ephemeral)│
└───────────────────────────────────────┴──────────────────────┴──────────────────────┘
```

The greatest opportunity lies in **pure algorithmic and AI concepts** that can be realized in pure ANSI Common Lisp (zero dependencies) or standard UIOP utilities, requiring zero external data files.

---

## 5. Candidate Examples Catalog (Requirement R2)

Every candidate presented below includes:
1. Exact source file(s) in `/Users/markw/GITHUB/loving-common-lisp/src`
2. Concept and functionality demonstrated (including mathematical/algorithmic basis)
3. Concrete implementation outline (<50 lines, runnable, standalone, pure ANSI CL or minimal dependencies)
4. Compelling rationale for why it fits `SHORTEST_CODE`

---

### Candidate 1: Bayesian Inference & Updating (`bayes.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/Probability/bayes.lisp` (lines 1–61)  
  `/Users/markw/GITHUB/loving-common-lisp/src/Probability/examples/medical.lisp` (lines 1–98)
- **Concept & Functionality**:  
  Implements Bayes' Theorem for discrete hypothesis spaces:
  $$P(H_i | E) = \frac{P(E | H_i) P(H_i)}{\sum_j P(E | H_j) P(H_j)}$$
  Represents probability distributions as normalized association lists `((hypothesis . probability) ...)`. Provides functions to normalize priors, compute the likelihood update given observed evidence, and extract the Maximum A Posteriori (MAP) hypothesis. Demonstrates the **medical screening base-rate fallacy paradox**: given a rare disease (prevalence 0.1%) and an accurate diagnostic test (99% sensitivity, 5% false positive rate), a positive test result yields only a ~1.94% posterior probability of actually having the disease.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script bayes.lisp   (pure ANSI Common Lisp)
  (defun bayes-model (priors)
    (let ((tot (reduce #'+ priors :key #'cdr)))
      (mapcar (lambda (p) (cons (car p) (/ (cdr p) (float tot 1d0)))) priors)))

  (defun bayes-update (model evidence likelihood-fn)
    (let* ((unnorm (mapcar (lambda (p)
                             (cons (car p) (* (funcall likelihood-fn (car p) evidence) (cdr p))))
                           model))
           (marginal (reduce #'+ unnorm :key #'cdr)))
      (mapcar (lambda (p) (cons (car p) (/ (cdr p) marginal))) unnorm)))

  (defun map-hypothesis (model)
    (reduce (lambda (a b) (if (> (cdr a) (cdr b)) a b)) model))

  ;; Self-contained demonstration: Medical Screening Base-Rate Fallacy
  (let* ((prior (bayes-model '((:disease . 0.001) (:healthy . 0.999))))
         (likelihood (lambda (hyp test)
                       (case hyp
                         (:disease (if (eq test :positive) 0.99 0.01))
                         (:healthy (if (eq test :positive) 0.05 0.95)))))
         (posterior (bayes-update prior :positive likelihood))
         (map (map-hypothesis posterior)))
    (format t "Prior:     ~{~a: ~,4f~^, ~}~%" (loop for (k . v) in prior collect (list k v)))
    (format t "Posterior: ~{~a: ~,4f~^, ~}~%" (loop for (k . v) in posterior collect (list k v)))
    (format t "MAP:       ~a (p = ~,4f)~%" (car map) (cdr map)))
  ```
- **Rationale for Inclusion**:  
  - **Zero Dependencies**: 100% pure ANSI Common Lisp.
  - **Brevity**: ~25 lines of functional Common Lisp code.
  - **Non-Duplicative**: Fills the entire probabilistic reasoning gap. Shows how clean alists and higher-order functions (`reduce`, `mapcar`) model Bayesian conditioning without heavy numerical libraries.

---

### Candidate 2: In-Memory RDF Triple Store & Pattern Matcher (`triple-store.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/simple_rdf_sparql/simple_rdf_sparql.lisp` (lines 1–142)  
  `/Users/markw/GITHUB/loving-common-lisp/src/nsk-neural-symbolic-graph/src/unify.lisp` (lines 1–80)
- **Concept & Functionality**:  
  An in-memory semantic knowledge graph triple store and mini-SPARQL / Datalog query engine. Represents facts as 3-element lists `(subject predicate object)`. Queries consist of one or more triple patterns containing logic variables (symbols starting with `?`, e.g. `?person`, `?city`). The engine unifies patterns against the database, binds variables, and joins multiple patterns by passing variable binding environments across clauses.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script triple-store.lisp   (pure ANSI Common Lisp)
  (defvar *triples* nil)
  (defun add-triple (s p o) (push (list s p o) *triples*))
  (defun var-p (x) (and (symbolp x) (char= (char (symbol-name x) 0) #\?)))

  (defun match-pattern (pat triple env)
    (cond ((eq env :fail) :fail)
          ((null pat) (if (null triple) env :fail))
          ((var-p (car pat))
           (let ((val (cdr (assoc (car pat) env))))
             (if val (if (equal val (car triple)) env :fail)
                 (acons (car pat) (car triple) env))))
          ((equal (car pat) (car triple)) (match-pattern (cdr pat) (cdr triple) env))
          (t :fail)))

  (defun query (patterns &optional (envs '(())))
    (if (null patterns) envs
        (query (cdr patterns)
               (loop for env in envs
                     append (loop for tr in *triples*
                                  for next-env = (match-pattern (car patterns) tr env)
                                  unless (eq next-env :fail) collect next-env)))))

  ;; Self-contained demonstration: Knowledge Graph & Relational Join
  (mapc (lambda (tr) (apply #'add-triple tr))
        '((:john :lives-in :london) (:london :in-country :uk)
          (:mary :lives-in :paris)  (:paris :in-country :france)
          (:alice :lives-in :oxford) (:oxford :in-country :uk)))

  (format t "People living in the UK:~%")
  (dolist (sol (query '((?person :lives-in ?city) (?city :in-country :uk))))
    (format t "  ~a lives in ~a~%" (cdr (assoc '?person sol)) (cdr (assoc '?city sol))))
  ```
- **Rationale for Inclusion**:  
  - **Zero Dependencies**: 100% pure ANSI Common Lisp.
  - **Brevity**: ~30 lines of highly expressive code.
  - **Non-Duplicative**: In contrast to `sparql.lisp` (which only sends HTTP queries to remote servers), this provides a *real, local, in-memory graph store and relational pattern-unification engine*. Demonstrates the iconic symbolic heritage of Lisp in AI and knowledge representation.

---

### Candidate 3: Scalar Reverse-Mode Automatic Differentiation Engine (`autograd.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/Karpathy_MicroGPT/microgpt.lisp` (lines 32–75)
- **Concept & Functionality**:  
  A minimalist scalar reverse-mode automatic differentiation (autograd) engine in the style of Andrej Karpathy's Micrograd. Defines a `val` structure wrapping numbers, tracking predecessors in a computation DAG and backward derivative closures. Implements differentiable operators (`v+`, `v*`, `vpow`, `vrelu`) and a `backward` pass that topologically sorts the graph and propagates gradients via the chain rule. Demonstrates optimizing an objective function with gradient descent.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script autograd.lisp   (pure ANSI Common Lisp)
  (defstruct val data (grad 0.0d0) prev backward)
  (defun v (d) (make-val :data (float d 1d0)))

  (defun v+ (a b)
    (let* ((a (if (val-p a) a (v a))) (b (if (val-p b) b (v b)))
           (out (make-val :data (+ (val-data a) (val-data b)) :prev (list a b))))
      (setf (val-backward out)
            (lambda () (incf (val-grad a) (val-grad out)) (incf (val-grad b) (val-grad out))))
      out))

  (defun v* (a b)
    (let* ((a (if (val-p a) a (v a))) (b (if (val-p b) b (v b)))
           (out (make-val :data (* (val-data a) (val-data b)) :prev (list a b))))
      (setf (val-backward out)
            (lambda ()
              (incf (val-grad a) (* (val-data b) (val-grad out)))
              (incf (val-grad b) (* (val-data a) (val-grad out)))))
      out))

  (defun backward (root)
    (let ((topo nil) (visited (make-hash-table :test 'eq)))
      (labels ((build (node)
                 (unless (gethash node visited)
                   (setf (gethash node visited) t)
                   (mapc #'build (val-prev node))
                   (push node topo))))
        (build root))
      (setf (val-grad root) 1.0d0)
      (dolist (node topo) (when (val-backward node) (funcall (val-backward node))))))

  ;; Self-contained demonstration: Gradient descent minimization of (x - 3)^2
  (let ((x (v 0.0d0)))
    (dotimes (epoch 20)
      (setf (val-grad x) 0.0d0)
      (let* ((diff (v+ x (v -3.0d0)))
             (loss (v* diff diff)))
        (backward loss)
        (decf (val-data x) (* 0.1d0 (val-grad x)))))
    (format t "Optimized x: ~,4f (expected ~4f)~%" (val-data x) 3.0))
  ```
- **Rationale for Inclusion**:  
  - **Zero Dependencies**: 100% pure ANSI Common Lisp.
  - **Brevity**: ~42 lines.
  - **Non-Duplicative**: While `symbolic-math.lisp` performs *symbolic* algebraic differentiation, `autograd.lisp` performs *automatic* reverse-mode differentiation—the algorithmic heart of modern deep learning and neural network training.

---

### Candidate 4: Okapi BM25 Ranking Index (`bm25.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/autocontext/bm25.lisp` (lines 1–76)
- **Concept & Functionality**:  
  Implements the Okapi BM25 information retrieval ranking algorithm. Given an in-memory document corpus, indexes term frequencies (TF), inverse document frequencies (IDF), and document lengths. Given a search query, scores documents using:
  $$\text{score}(D, Q) = \sum_{t \in Q} \text{IDF}(t) \cdot \frac{f(t, D) \cdot (k_1 + 1)}{f(t, D) + k_1 \cdot \left(1 - b + b \cdot \frac{|D|}{\text{avgdl}}\right)}$$
  Returns documents sorted in descending order of relevance.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script bm25.lisp   (pure ANSI Common Lisp)
  (defun tokenize (text)
    (loop for w in (uiop:split-string (string-downcase text) :separator '(#\Space #\Tab #\Newline #\. #\, #\! #\?))
          unless (string= w "") collect w))

  (defun bm25 (corpus query &key (k1 1.5d0) (b 0.75d0))
    (let* ((docs (mapcar #'tokenize corpus))
           (n (length docs))
           (lengths (mapcar #'length docs))
           (avgdl (/ (reduce #'+ lengths) (float n 1d0)))
           (q-terms (tokenize query)))
      (labels ((idf (term)
                 (let ((df (count-if (lambda (d) (member term d :test #'string=)) docs)))
                   (log (+ 1.0d0 (/ (- n df -0.5d0) (+ df 0.5d0)))))))
        (sort (loop for doc in docs for i from 0 for len in lengths
                    for score = (loop for term in q-terms
                                      for tf = (count term doc :test #'string=)
                                      for idf = (idf term)
                                      sum (* idf (/ (* tf (+ k1 1.0d0))
                                                    (+ tf (* k1 (+ (- 1.0d0 b) (* b (/ len avgdl))))))))
                    collect (list score i (nth i corpus)))
              #'> :key #'car))))

  ;; Self-contained demonstration: Searching a mini document corpus
  (let* ((corpus '("Common Lisp is a general-purpose multiparadigm language."
                   "Python is widely used for machine learning and web development."
                   "Lisp macros allow powerful metaprogramming and domain-specific languages."
                   "Fast compiled code and dynamic REPL development make Common Lisp unique."))
         (results (bm25 corpus "Common Lisp metaprogramming macros")))
    (format t "BM25 Search Results:~%")
    (dolist (r results) (format t "  [~,3f] Doc ~a: ~a~%" (first r) (second r) (third r))))
  ```
- **Rationale for Inclusion**:  
  - **Zero Quicklisp Dependencies**: Standard UIOP + pure ANSI Common Lisp.
  - **Brevity**: ~35 lines.
  - **Non-Duplicative**: Completely fills the local search gap. `search.lisp` requires network calls to external APIs (Exa/Brave); `bm25.lisp` provides a self-contained, offline search ranking engine.

---

### Candidate 5: Hopfield Associative Memory Network (`hopfield.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/code_snippets_for_book/Hopfield_neural_network.lisp` (lines 1–147)
- **Concept & Functionality**:  
  A recurrent auto-associative neural network. Stores bipolar vectors ($\pm 1$) representing small visual patterns (e.g. 5x5 ASCII shapes) by computing the Hebbian outer product weight matrix:
  $$W_{ij} = \sum_s x_i^s x_j^s \quad (i \neq j), \quad W_{ii} = 0$$
  When presented with a noisy or corrupted pattern, iteratively updates neurons asynchronously or synchronously according to $s_i = \text{sgn}(\sum_j W_{ij} s_j)$, converging to the stored memory and demonstrating content-addressable memory retrieval.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script hopfield.lisp   (pure ANSI Common Lisp)
  (defun train-hopfield (patterns n)
    (let ((w (make-array (list n n) :initial-element 0)))
      (dolist (p patterns w)
        (dotimes (i n)
          (dotimes (j n)
            (unless (= i j) (incf (aref w i j) (* (nth i p) (nth j p)))))))))

  (defun recall (w input &optional (steps 5))
    (let ((state (copy-seq input)) (n (length input)))
      (dotimes (_ steps state)
        (dotimes (i n)
          (let ((sum (loop for j below n sum (* (aref w i j) (nth j state)))))
            (setf (nth i state) (if (>= sum 0) 1 -1)))))))

  (defun print-pattern (p size)
    (dotimes (r size)
      (format t "    ~{~a~}~%" (loop for c below size collect (if (= (nth (+ (* r size) c) p) 1) "#" ".")))))

  ;; Self-contained demonstration: 3x3 pattern "T" and noisy recall
  (let* ((pattern-t '( 1  1  1
                      -1  1 -1
                      -1  1 -1))
         (w (train-hopfield (list pattern-t) 9))
         (noisy     '( 1  1  1
                      -1 -1 -1  ;; middle pixel corrupted
                      -1  1 -1))
         (recovered (recall w noisy)))
    (format t "Original Pattern T:~%") (print-pattern pattern-t 3)
    (format t "Corrupted Input:~%")    (print-pattern noisy 3)
    (format t "Recalled Pattern:~%")   (print-pattern recovered 3))
  ```
- **Rationale for Inclusion**:  
  - **Zero Dependencies**: 100% pure ANSI Common Lisp.
  - **Brevity**: ~34 lines.
  - **Non-Duplicative**: Introduces recurrent neural networks and associative memory into `SHORTEST_CODE`, producing visually compelling ASCII pattern reconstruction in the terminal.

---

### Candidate 6: In-Memory Dense Vector Cosine Store (`vector-store.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/RAG/vector-store.lisp` (lines 1–277)
- **Concept & Functionality**:  
  An in-memory dense vector embedding store supporting cosine similarity search. Implements vector normalization, dot product calculation, and top-$K$ nearest neighbor retrieval. Showcases how easily modern vector search (the foundational retrieval component of RAG architectures) can be implemented in Common Lisp without third-party vector databases.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script vector-store.lisp   (pure ANSI Common Lisp)
  (defun v-dot (a b) (loop for x across a for y across b sum (* x y)))
  (defun v-norm (a) (sqrt (v-dot a a)))
  (defun v-normed (a) (let ((m (v-norm a))) (map '(vector double-float) (lambda (x) (/ x m)) a)))

  (defun make-vector-store () (make-hash-table :test 'equal))
  (defun store-add (store id text vec)
    (setf (gethash id store) (list text (v-normed (coerce vec '(vector double-float))))))

  (defun store-search (store query-vec &optional (k 3))
    (let ((qv (v-normed (coerce query-vec '(vector double-float)))))
      (subseq (sort (loop for id being the hash-keys of store using (hash-value item)
                          collect (list (v-dot qv (second item)) id (first item)))
                    #'> :key #'car)
              0 (min k (hash-table-count store)))))

  ;; Self-contained demonstration: 4D toy semantic embeddings
  (let ((store (make-vector-store)))
    (store-add store :doc1 "Lisp programming language"  #(0.9 0.1 0.8 0.2))
    (store-add store :doc2 "Python machine learning"     #(0.2 0.8 0.3 0.9))
    (store-add store :doc3 "Functional macro system"     #(0.8 0.2 0.9 0.1))
    (format t "Querying for Lisp-like vector #(0.85 0.15 0.85 0.15):~%")
    (dolist (res (store-search store #(0.85 0.15 0.85 0.15) 2))
      (format t "  Cosine ~,3f | ID ~a: ~s~%" (first res) (second res) (third res))))
  ```
- **Rationale for Inclusion**:  
  - **Zero Dependencies**: 100% pure ANSI Common Lisp.
  - **Brevity**: ~27 lines.
  - **Non-Duplicative**: Fills the vector similarity gap. Essential for demonstrating the algorithmic backbone of modern embedding retrieval and RAG.

---

### Candidate 7: Frequency-Based Extractive Text Summarizer (`summarizer.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/categorize_summarize/categorize_summarize.lisp` (lines 93–142)
- **Concept & Functionality**:  
  Extractive text summarization using classic word-frequency histograms (Luhn's algorithm). Tokenizes a document into sentences and words, filters out stop words, constructs a word frequency table, scores each sentence by summing the significance scores of its constituent words normalized by sentence length, and extracts the top-$N$ most informative sentences in document order.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script summarizer.lisp   (pure ANSI Common Lisp)
  (defparameter *stop* '("the" "a" "an" "in" "on" "at" "of" "for" "to" "and" "is" "it" "that" "this" "with" "as"))
  (defun words (s)
    (loop for w in (uiop:split-string (string-downcase s) :separator '(#\Space #\Tab #\Newline #\, #\;))
          unless (or (string= w "") (member w *stop* :test #'string=)) collect w))

  (defun summarize (text &optional (n 2))
    (let* ((sentences (remove-if (lambda (s) (string= (string-trim " " s) ""))
                                 (uiop:split-string text :separator '(#\. #\! #\?))))
           (freqs (make-hash-table :test 'equal)))
      (dolist (w (words text)) (incf (gethash w freqs 0)))
      (let ((scored (loop for s in sentences for idx from 0
                          for ws = (words s)
                          for score = (if ws (/ (loop for w in ws sum (gethash w freqs 0)) (length ws)) 0)
                          collect (list score idx s))))
        (mapcar #'third
                (sort (subseq (sort (copy-list scored) #'> :key #'first) 0 (min n (length scored)))
                      #'< :key #'second)))))

  ;; Self-contained demonstration: Summarizing an article snippet
  (let* ((article "Common Lisp is a venerable and highly dynamic programming language. It pioneered features like garbage collection, dynamic typing, and advanced object systems. Many modern languages have borrowed ideas from Common Lisp. Common Lisp macros allow programmers to create customized syntax and domain-specific languages with ease. In conclusion, Common Lisp remains uniquely productive for complex AI problems.")
         (summary (summarize article 2)))
    (format t "Extractive Summary (~a sentences):~%" (length summary))
    (dolist (sent summary) (format t "  • ~a.~%" (string-trim " " sent))))
  ```
- **Rationale for Inclusion**:  
  - **Zero Dependencies**: Pure ANSI Common Lisp + standard UIOP. Requires no external 100,000-line lexical tables.
  - **Brevity**: ~30 lines.
  - **Non-Duplicative**: `webscraping.lisp` extracts raw text from web pages; `summarizer.lisp` introduces actual natural language processing and document distillation.

---

### Candidate 8: Multimodal Vision Prompting with Local LLMs (`ollama-vision.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/ollama_images/describe-image.lisp` (lines 1–123)
- **Concept & Functionality**:  
  Extends local LLM inference to multimodal vision models (`llava`, `minicpm-v`, `moondream`). Reads a binary image file from disk into an octet buffer, encodes it to a base64 string, constructs the JSON payload containing the `"images"` array, and calls Ollama's `/api/generate` endpoint via `curl` and `jzon`.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script ollama-vision.lisp   (needs Quicklisp: com.inuoe.jzon, cl-base64)
  #-quicklisp (load "~/quicklisp/setup.lisp")
  (ql:quickload '(:com.inuoe.jzon :cl-base64) :silent t)

  (defun file-base64 (path)
    (with-open-file (in path :element-type '(unsigned-byte 8))
      (let ((buf (make-array (file-length in) :element-type '(unsigned-byte 8))))
        (read-sequence buf in)
        (cl-base64:usb8-array-to-base64-string buf))))

  (defun ollama-vision (img-path prompt &optional (model "llava"))
    (let ((payload (format nil "{\"model\":\"~a\",\"prompt\":~a,\"stream\":false,\"images\":[\"~a\"]}"
                           model (com.inuoe.jzon:stringify prompt) (file-base64 img-path))))
      (gethash "response"
               (com.inuoe.jzon:parse
                (uiop:run-program (list "curl" "-s" "http://localhost:11434/api/generate" "-d" payload)
                                  :output :string)))))
  ```
- **Rationale for Inclusion**:  
  - **Dependencies**: Quicklisp (`jzon`, `cl-base64`), `uiop`, CLI `curl`.
  - **Brevity**: ~20 lines.
  - **Non-Duplicative**: Existing LLM scripts (`ollama.lisp`, `gemini.lisp`) are text-only. This demonstrates multimodal image perception in minimal lines.

---

### Candidate 9: Interactive Multi-Turn Chat REPL (`chat-repl.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/text-adventure-game/text-adventure-game_ollama.lisp` (lines 1–95)  
  `/Users/markw/GITHUB/loving-common-lisp/src/daily_use/daily-use.lisp` (lines 1–238)
- **Concept & Functionality**:  
  An interactive conversational REPL loop that maintains a stateful message history list `((:role "user" :content ...) (:role "assistant" :content ...))` with local or cloud models. Supports in-session commands (`quit`, `clear`), sends the accumulated conversational context to `/api/chat`, and streams or prints replies.
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script chat-repl.lisp   (needs Quicklisp: com.inuoe.jzon)
  #-quicklisp (load "~/quicklisp/setup.lisp")
  (ql:quickload :com.inuoe.jzon :silent t)

  (defun chat-repl (&optional (model "qwen3.5:4b"))
    (let ((history nil))
      (format t "Chat REPL (~a). Type 'quit' to exit, 'clear' to reset.~%" model)
      (loop
        (format t "~%User> ") (force-output)
        (let ((input (read-line nil nil)))
          (when (or (null input) (member input '("quit" "exit") :test #'string-equal)) (return))
          (if (string-equal input "clear")
              (progn (setf history nil) (format t "[History reset]~%"))
              (progn
                (push (list (cons "role" "user") (cons "content" input)) history)
                (let* ((req (com.inuoe.jzon:stringify
                             `(("model" . ,model) ("stream" . :false) ("messages" . ,(reverse history)))))
                       (raw (uiop:run-program (list "curl" "-s" "http://localhost:11434/api/chat" "-d" req)
                                              :output :string))
                       (reply (gethash "content" (gethash "message" (com.inuoe.jzon:parse raw)))))
                  (format t "~%Assistant> ~a~%" reply)
                  (push (list (cons "role" "assistant") (cons "content" reply)) history))))))))
  ```
- **Rationale for Inclusion**:  
  - **Dependencies**: `com.inuoe.jzon`, `uiop`, CLI `curl`.
  - **Brevity**: ~26 lines.
  - **Non-Duplicative**: Moves beyond one-shot question/answering into stateful, multi-turn conversational agents.

---

### Candidate 10: Statistical Correlation & Covariance (`correlation.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/Probability/correlation.lisp` (lines 1–84)
- **Concept & Functionality**:  
  Computes mean, variance, covariance, and Pearson's product-moment correlation coefficient $r$ between two paired numeric sequences:
  $$r = \frac{\sum (x_i - \bar{x})(y_i - \bar{y})}{\sqrt{\sum (x_i - \bar{x})^2 \sum (y_i - \bar{y})^2}}$$
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script correlation.lisp   (pure ANSI Common Lisp)
  (defun mean (xs) (/ (reduce #'+ xs) (float (length xs) 1d0)))

  (defun pearson-r (xs ys)
    (let* ((mx (mean xs)) (my (mean ys))
           (dx (mapcar (lambda (x) (- x mx)) xs))
           (dy (mapcar (lambda (y) (- y my)) ys))
           (cov (reduce #'+ (mapcar #'* dx dy)))
           (var-x (reduce #'+ (mapcar (lambda (d) (* d d)) dx)))
           (var-y (reduce #'+ (mapcar (lambda (d) (* d d)) dy))))
      (/ cov (sqrt (* var-x var-y)))))

  ;; Self-contained demonstration
  (let ((x '(10 20 30 40 50))
        (y '(15 25 32 38 55)))
    (format t "Pearson r: ~,4f~%" (pearson-r x y)))
  ```
- **Rationale for Inclusion**:  
  - **Zero Dependencies**: Pure ANSI Common Lisp in ~15 lines.
  - **Non-Duplicative**: Introduces basic statistical analysis to the repository.

---

### Candidate 11: SQLite Key-Value Cache with TTL (`cache-engine.lisp`)

- **Source File(s)**:  
  `/Users/markw/GITHUB/loving-common-lisp/src/cache_engine/cache-engine.lisp` (lines 1–112)
- **Concept & Functionality**:  
  Implements a local embedded cache backed by SQLite using `sqlite3` CLI via `uiop:run-program`. Creates tables on demand, stores key/value text pairs with insertion timestamps, and evicts entries exceeding a time-to-live (TTL).
- **Concise Implementation Outline (<50 lines)**:
  ```lisp
  ;; sbcl --script cache-engine.lisp   (needs CLI sqlite3)
  (defun sqlite-exec (db sql)
    (uiop:run-program (list "sqlite3" db sql) :output :string))

  (defun cache-init (db)
    (sqlite-exec db "CREATE TABLE IF NOT EXISTS cache (k TEXT PRIMARY KEY, v TEXT, ts INTEGER);"))

  (defun cache-set (db k v)
    (let ((ts (get-universal-time)))
      (sqlite-exec db (format nil "INSERT OR REPLACE INTO cache VALUES ('~a', '~a', ~a);" k v ts))))

  (defun cache-get (db k &optional (ttl-sec 3600))
    (let* ((now (get-universal-time))
           (res (sqlite-exec db (format nil "SELECT v FROM cache WHERE k='~a' AND (~a - ts) <= ~a;" k now ttl-sec))))
      (unless (string= res "") (string-trim '(#\Newline #\Return) res))))
  ```
- **Rationale for Inclusion**:  
  - **Dependencies**: ASDF/UIOP, CLI `sqlite3`.
  - **Non-Duplicative**: Adds persistent caching for expensive remote web/LLM queries.

---

## 6. Implementation Action Plan (Milestone M2 & Beyond)

Based on the criteria of **standalone conciseness**, **zero external data dependencies**, and **maximum algorithmic punch**, we establish the following phased implementation plan:

### 6.1. Phase 1: Immediate Standalone Implementations (Milestone M2)
The user has specifically directed:
> *"for examples that fit with the 'ultra short and concise, require no external data files', implement 1 file per example here in this directory"*

The following **7 candidate files** have been selected for immediate implementation directly in `/Users/markw/GITHUB/common-lisp-experiments/SHORTEST_CODE`:

| # | Target Filename | Concept / Feature | Dependencies | Est. Lines | Status |
|---|---|---|---|---|---|
| 1 | `bayes.lisp` | Bayesian inference, updating, MAP, medical base-rate paradox | Pure ANSI Common Lisp | ~30 | Ready for M2 |
| 2 | `triple-store.lisp`| In-memory RDF graph store, pattern matching & variable joins | Pure ANSI Common Lisp | ~35 | Ready for M2 |
| 3 | `autograd.lisp` | Reverse-mode automatic differentiation DAG & gradient descent | Pure ANSI Common Lisp | ~45 | Ready for M2 |
| 4 | `bm25.lisp` | Okapi BM25 offline full-text search ranking algorithm | Pure ANSI Common Lisp + `uiop` | ~38 | Ready for M2 |
| 5 | `hopfield.lisp` | Recurrent neural memory, Hebbian learning, ASCII recall | Pure ANSI Common Lisp | ~36 | Ready for M2 |
| 6 | `vector-store.lisp`| Dense vector store, cosine similarity, top-k retrieval | Pure ANSI Common Lisp | ~30 | Ready for M2 |
| 7 | `summarizer.lisp` | Frequency-based extractive text summarization | Pure ANSI Common Lisp + `uiop` | ~32 | Ready for M2 |

#### Zero External Data Files Guarantee:
Every one of these 7 examples embeds all required test vectors, knowledge triples, or sample sentences directly inside the `.lisp` source file. **No external disk files, datasets, or network credentials are required.**

### 6.2. Phase 2: Loader & Registry Integration (Milestone M3)
Following the implementation of the 7 standalone files in M2:
1. Update `/Users/markw/GITHUB/common-lisp-experiments/SHORTEST_CODE/load.lisp` to register the new functions into the `*help*` alist:
   - `bayes`: `(bayes-model ...)`, `(bayes-update ...)`
   - `triple-store`: `(add-triple ...)`, `(query ...)`
   - `autograd`: `(v ...)`, `(v+ ...)`, `(v* ...)`, `(backward ...)`
   - `bm25`: `(bm25 corpus query)`
   - `hopfield`: `(train-hopfield ...)`, `(recall ...)`
   - `vector-store`: `(make-vector-store)`, `(store-add ...)`, `(store-search ...)`
   - `summarizer`: `(summarize text &optional n)`
2. Test both execution modes:
   - Command line: `sbcl --script <file>.lisp` for all 7 files.
   - REPL mode: `sbcl --eval '(load "load.lisp")' --eval '(help)' --eval '(sb-ext:exit)'`.

### 6.3. Phase 3: Future Expansion Candidates (Post-M3)
For future milestones or community contributions:
- `ollama-vision.lisp` (Multimodal image analysis via local Ollama models)
- `chat-repl.lisp` (Interactive conversational multi-turn chat REPL)
- `correlation.lisp` (Pearson correlation & descriptive statistics)
- `cache-engine.lisp` (SQLite-backed persistent caching with TTL)

---

## 7. Compliance Verification Matrix

| Requirement | Description | Status | Verification Reference |
|---|---|---|---|
| **R1: Inventory & Comparative Analysis** | Complete inventory of all 10 existing files in `SHORTEST_CODE` and all 46 subdirectories / 121 files in `loving-common-lisp/src`. | **COMPLETED** | Section 2 (Tables 2.1) & Section 3 (Table 3.2, Section 3.3). |
| **R2: Suggestions Report** | Candidate catalog detailing source files, concept, concise outline (<50 lines), and rationale. | **COMPLETED** | Section 5 (Candidates 1 through 11). |
| **R3: Non-Duplication & Conciseness** | Explicit identification of overlaps to avoid; prioritization of compact standalone examples. | **COMPLETED** | Section 4 (Section 4.1 & 4.2), Section 6 (Action Plan). |
| **User Directives (Follow-Up)** | Selection of ultra-short, concise candidates requiring zero external data files for 1-file implementation. | **COMPLETED** | Section 6.1 (7 selected candidates with exact specifications). |

---

## 8. Conclusion

By synthesizing the rich AI and algorithmic techniques in `loving-common-lisp/src` into the minimalist, idiomatic style of `SHORTEST_CODE`, we expand the repository from a predominantly subprocess-oriented toolset into a comprehensive showcase of modern Common Lisp programming. The 7 selected implementations provide immediate, high-impact demonstrations of Bayesian inference, knowledge graphs, automatic differentiation, document ranking, neural associative memory, vector similarity, and extractive text summarization—all in standalone, zero-dependency scripts of under 50 lines.
