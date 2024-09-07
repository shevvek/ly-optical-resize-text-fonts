\version "2.25.18"

#(use-modules (ice-9 and-let-star))

#(define ((char-height c extent-proc) layout font)
   (let* ((fonts (assoc-get 'fonts (ly:output-def-lookup layout 'property-defaults)))
          (props `(((font-encoding . latin1)
                    (font-family . ,font)
                    (fonts . ,(cons* '(default-serif . "LilyPond Serif")
                                     '(default-sans . "LilyPond Sans Serif")
                                     '(default-mono . "LilyPond Monospace")
                                     fonts)))))
          (stencil (interpret-markup layout props c))
          (height (interval-length (extent-proc stencil Y))))
     height))

#(define x-height (char-height "x" ly:stencil-extent))
#(define x-true-height (char-height "x" stencil-true-extent))
#(define cap-height (char-height "I" ly:stencil-extent))
#(define cap-true-height (char-height "I" stencil-true-extent))

#(define (init-font-size-adjustments score-ctx)
   (let* ((layout (ly:context-output-def score-ctx))
          (font-adjustments (ly:output-def-lookup layout 'font-adjustments)))
     
     (define (get-font-dimen font dimen)
       (or (assq-ref (cdr font) dimen)
           (let* ((dimen-proc (module-ref (current-module) dimen))
                  (dimen-val (dimen-proc layout (car font))))
             (set-cdr! font (acons dimen dimen-val (cdr font)))
             dimen-val)))
     
     (define (font-adjustment font)
       (unless (assq-ref (cdr font) 'size-correction)
         (let* ((dimen (car (assq-ref (cdr font) 'normalize-to)))
                (reference (cdr (assq-ref (cdr font) 'normalize-to)))
                (my-size (get-font-dimen font dimen))
                (ref-size (if (symbol? reference)
                              (get-font-dimen (or (assq reference font-adjustments)
                                                  (and (set! font-adjustments 
                                                             (acons reference '() font-adjustments))
                                                       (assq reference font-adjustments)))
                                              dimen)
                              reference))
                (size-correction (magnification->font-size (/ ref-size my-size))))
           (set-cdr! font (acons 'size-correction size-correction (cdr font))))))
     
     (for-each font-adjustment font-adjustments)
     (ly:output-def-set-variable! layout 'font-adjustments font-adjustments)
     (ly:message "~a" (ly:output-def-lookup layout 'font-adjustments))
     ))

#(define (normalize-size layout props arg)
   (or (and-let* ((font-family (chain-assoc-get 'font-family props 'serif))
                  (adjustments (assq-ref (ly:output-def-lookup layout 'font-adjustments) font-family))
                  (correction (assq-ref adjustments 'size-correction)))
         (make-fontsize-markup correction arg))
       arg))

normalizeFonts = \with {
  \applyContext #init-font-size-adjustments
}

\paper {
  property-defaults.string-transformers = #`(,normalize-size
                                             ,ly:perform-text-replacements)
  property-defaults.fonts.serif = "Arno Pro SmText"
}



\score {
  { c'1^\markup "bar" }
  \layout {
    font-adjustments.serif.normalize-to = #'(x-height . default-serif)
    \context {
      \Score
      \normalizeFonts
    }
  }
}

{ c'1^\markup\override #'(fonts . ((serif . "LilyPond Serif"))) "bar" }
