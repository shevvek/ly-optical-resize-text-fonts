\version "2.25.18"
% -*- master: tests.ly;

#(use-modules (ice-9 and-let-star))

#(define-public ((char-height c extent-proc) layout font)
   (let* ((fonts (assq-ref (ly:output-def-lookup layout 'property-defaults)
                           'fonts))
          (props `(((font-encoding . latin1)
                    (font-family . ,font)
                    (fonts . ,(cons* '(default-serif . "LilyPond Serif")
                                     '(default-sans . "LilyPond Sans Serif")
                                     '(default-mono . "LilyPond Monospace")
                                     fonts)))))
          (stencil (interpret-markup layout props c))
          (height (interval-length (extent-proc stencil Y))))
     height))

#(define-public x-height (char-height "x" ly:stencil-extent))
#(define-public x-true-height (char-height "x" stencil-true-extent))
#(define-public cap-height (char-height "I" ly:stencil-extent))
#(define-public cap-true-height (char-height "I" stencil-true-extent))

#(define-public (init-font-size-corrections layout-ctx)
   "Reads fonts-info from this context's output-def. For each font-family
with normalize-to defined in fonts-info, populate size-correction to match
that font-family's height to either the height of a reference font-family
or directly to a reference height in staff spaces."
   (let* ((layout (ly:context-output-def layout-ctx))
          (fonts-info (ly:output-def-lookup layout 'fonts-info)))
     
     (define (get-font-dimen font dimen)
       ;; Cache calculated font heights in that font's fonts-info entry
       (or (assq-ref (cdr font) dimen)
           (let* ((dimen-proc (module-ref (current-module) dimen))
                  (dimen-val (dimen-proc layout (car font))))
             (set-cdr! font (acons dimen dimen-val (cdr font)))
             dimen-val)))
     
     (define (set-correction! font)
       ;; If a correction was already calculated for this font, don't redo
       (and-let* (((not (assq-ref (cdr font) 'size-correction)))
                  (normalize-to (assq-ref (cdr font) 'normalize-to))
                  (dimen (car normalize-to))
                  (reference (cdr normalize-to))
                  (my-size (get-font-dimen font dimen))
                  ;; If reference is a symbol, it is the name of a font-family
                  ;; we will adjust the size of this font to match that one,
                  ;; calculated using the procedure dimen (e.g. x-height).
                  ;; Otherwise, reference is a number and we will adjust this
                  ;; font's height to match that number of staff spaces.
                  (ref-size (if (symbol? reference)
                                (get-font-dimen
                                 ;; if the reference font is missing from
                                 ;; fonts-info, add an empty entry and pass it
                                 (or (assq reference fonts-info)
                                     (and (set! fonts-info 
                                                (acons reference '() fonts-info))
                                          (assq reference fonts-info)))
                                 dimen)
                                reference))
                  ;; constantly converting magsteps <-> ratios is inefficient :(
                  (size-correction (magnification->font-size (/ ref-size
                                                                my-size))))
           (set-cdr! font (acons 'size-correction size-correction
                                 (cdr font)))))
     
     (for-each set-correction! fonts-info)
     (ly:output-def-set-variable! layout 'fonts-info fonts-info)
     (ly:debug (format #f "fonts-info: ~y"
                         (ly:output-def-lookup layout 'fonts-info)))))

#(define-markup-command (normalize-size layout props arg)
   (markup?)
   #:category font
   #:properties (fontsize-markup
                 (font-family 'serif))
   "Adjust font size based on the size-correction defined in fonts-info for this
font-family, if it is defined."
   (or (and-let* ((font-info (assq-ref (ly:output-def-lookup layout 'fonts-info)
                                       font-family))
                  (correction (assq-ref font-info 'size-correction)))
         (fontsize-markup layout props correction arg))
       (interpret-markup layout props arg)))

#(define-markup-command (select-optical-variant layout props arg)
   (markup?)
   #:category font
   #:properties ((font-size 0)
                 (font-family 'serif))
   "If fonts-info for the current font-family defines an optical-sizes alist,
change the font-family to the appropriate optical size varient family, based on
the current absolute font size."
   (or (and-let* ((font-info (assq-ref (ly:output-def-lookup layout 'fonts-info)
                                       font-family))
                  (optical-sizes (assq-ref font-info 'optical-sizes))
                  (base-size (ly:output-def-lookup layout 'text-font-size))
                  (pt-size (* base-size (magstep font-size)))
                  (this-size (assoc pt-size optical-sizes
                                    ;; optical-sizes keys are intervals
                                    ;; match if pt-size is within it
                                    (lambda (key alistcar)
                                      (and (< (car alistcar) key)
                                           (<= key (cdr alistcar))))))
                  (optical-family (symbol-append font-family '- (cdr this-size))))
          (override-markup layout props `(font-family . ,optical-family) arg))
       (interpret-markup layout props arg)))

#(define-public (select-variant-and-normalize layout props arg)
   (markup #:select-optical-variant #:normalize-size arg))

#(define-public ((add-default-string-transformer transformer) ctx)
   (let* ((layout (ly:context-output-def ctx))
          (property-defaults (ly:output-def-lookup layout 'property-defaults))
          (string-transformers (assq-ref property-defaults 'string-transformers)))
     (ly:output-def-set-variable! layout 'property-defaults
                                  (assq-set! property-defaults 'string-transformers 
                                             (cons transformer string-transformers)))))
     
normalizeOpticalTextSizes = \with {
  \applyContext #init-font-size-corrections
  \applyContext #(add-default-string-transformer select-variant-and-normalize)
}
