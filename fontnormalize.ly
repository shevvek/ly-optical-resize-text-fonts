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
       (and-let* (((not (assq-ref (cdr font) 'size-correction)))
                  (normalize-to (assq-ref (cdr font) 'normalize-to))
                  (dimen (car normalize-to))
                  (reference (cdr normalize-to))
                  (my-size (get-font-dimen font dimen))
                  (ref-size (if (symbol? reference)
                                (get-font-dimen (or (assq reference font-adjustments)
                                                    (and (set! font-adjustments 
                                                               (acons reference '() font-adjustments))
                                                         (assq reference font-adjustments)))
                                                dimen)
                                reference))
                  (size-correction (magnification->font-size (/ ref-size my-size))))
           (set-cdr! font (acons 'size-correction size-correction (cdr font)))))
     
     (for-each font-adjustment font-adjustments)
     (ly:output-def-set-variable! layout 'font-adjustments font-adjustments)
   ;   (ly:message "~a" (ly:output-def-lookup layout 'font-adjustments))
     ))

#(define-markup-command (normalize-size layout props arg) (markup?)
   #:properties (fontsize-markup
                 (font-family 'serif))
   (or (and-let* ((adjustments (assq-ref (ly:output-def-lookup layout 'font-adjustments) font-family))
                  (correction (assq-ref adjustments 'size-correction)))
         (fontsize-markup layout props correction arg))
       (interpret-markup layout props arg)))

#(define-markup-command (select-optical-variant layout props arg) (markup?)
   #:properties ((font-size 0)
                 (font-family 'serif))
   (or (and-let* ((base-size (ly:output-def-lookup layout 'text-font-size))
                  (pt-size (* base-size (magstep font-size)))
                  (adjustments (assq-ref (ly:output-def-lookup layout 'font-adjustments) font-family))
                  (optical-sizes (assq-ref adjustments 'optical-sizes))
                  (this-size (assoc pt-size optical-sizes (lambda (key alistcar)
                                                            (and (< (car alistcar) key)
                                                                 (<= key (cdr alistcar))))))
                  (optical-family (symbol-append font-family '- (cdr this-size))))
          (override-markup layout props `(font-family . ,optical-family) arg))
       (interpret-markup layout props arg)))

#(define (select-variant-and-normalize layout props arg)
   (markup #:select-optical-variant #:normalize-size arg))

\layout {
  \context {
    \Global
    \applyContext #init-font-size-adjustments
  }
}

\paper {
  property-defaults.string-transformers = #`(,select-variant-and-normalize
                                             ,ly:perform-text-replacements)
  property-defaults.fonts.serif-caption = "Arno Pro Caption"
  font-adjustments.serif-caption.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-small = "Arno Pro SmText"
  font-adjustments.serif-small.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-subhead = "Arno Pro Subhead"
  font-adjustments.serif-subhead.normalize-to = #'(x-height . default-serif)
  property-defaults.fonts.serif-display = "Arno Pro Display"
  font-adjustments.serif-display.normalize-to = #'(x-height . default-serif)
  font-adjustments.serif.optical-sizes = #'(((-inf.0 . 8.5) . caption)
                                            ((8.5 . 12.5) . small) ; should be 11
                                            ((12.5 . 21.5) . subhead) ; should be 14
                                            ((21.5 . +inf.0) . display))
}

% #(set-global-staff-size 11.3)

{ c'1^\markup"bar" }
