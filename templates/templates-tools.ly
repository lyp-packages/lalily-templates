;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%                                                                             %
;% This file is part of openLilyLib,                                           %
;%                      ===========                                            %
;% the community library project for GNU LilyPond                              %
;% (https://github.com/openlilylib)                                            %
;%              -----------                                                    %
;%                                                                             %
;% Library: lalily-templates                                                   %
;%          ================                                                   %
;%                                                                             %
;% openLilyLib is free software: you can redistribute it and/or modify         %
;% it under the terms of the GNU General Public License as published by        %
;% the Free Software Foundation, either version 3 of the License, or           %
;% (at your option) any later version.                                         %
;%                                                                             %
;% openLilyLib is distributed in the hope that it will be useful,              %
;% but WITHOUT ANY WARRANTY; without even the implied warranty of              %
;% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               %
;% GNU General Public License for more details.                                %
;%                                                                             %
;% You should have received a copy of the GNU General Public License           %
;% along with openLilyLib. If not, see <http://www.gnu.org/licenses/>.         %
;%                                                                             %
;% openLilyLib is maintained by Urs Liska, ul@openlilylib.org                  %
;% lalily-templates is maintained by Jan-Peter Voigt, jp.voigt@gmx.de          %
;% and others.                                                                 %
;%       Copyright Jan-Peter Voigt, Urs Liska, 2017                            %
;%                                                                             %
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\version "2.18.0"

#(define lalily-relincl-tmp (ly:get-option 'relative-includes))
#(ly:set-option 'relative-includes #t)
\include "../lalily.ly"
#(ly:set-option 'relative-includes lalily-relincl-tmp)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% some tools

% return list - the parser can return a list, given in dot-notation
\parserDefine Path
#(define-scheme-function (parser location p)(list?) p)

% create a symbol list from string separated by optional character 's' (= '/')
\parserDefine PathS
#(define-scheme-function (parser location s p)((char? #\/) string?)
   (map (lambda (e) (if (> (string-length e) 0) (string->symbol e) '/)) (string-split p s)))

% create a pair from a list (that is the first two elements)
\parserDefine Pair
#(define-scheme-function (parser location p)(list?)
   (cond
    ((>= (length p) 2)
     (if (> (length p) 2)
         (ly:input-warning location "more than 2 elements: ~A" p))
     (cons (car p) (cadr p)))
    ((> (length p) 0) (cons (car p) #f))
    (else '(#f . #f))
    ))
% create a pair from a string
\parserDefine PairS
#(define-scheme-function (parser location s p)((char? #\|) string?)
   (Pair (string-split p s)))

% give a template warning
\parserDefine deprecateTemplate
#(define-void-function (parser location)()
   (ly:input-warning location "template [~A] is deprecated!" (glue-list (get-current-template) ".")))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% templates

% mirror another music-folder
% needs option 'mirror-path
% may set other options fo the inherited templated
\registerTemplate lalily.mirror
#(define-music-function (parser location piece options)(list? list?)
   (let ((path (assoc-get 'mirror-path options #f #f)))
     (if (not (list? path))
         (begin
          (ly:input-warning location "no mirror-path! (~A | ~A)" path piece)
          (set! path '(..))
          ))
     #{
       \createScoreWithOptions #path #options
     #}))

% chord mode
\registerTemplate lalily.chords
#(define-music-function (parser location piece options)(list? list?)
   (let ((mods (assoc-get 'context-mods options #f #f)))
     #{
       \new ChordNames \with {
         $(if (ly:context-mod? mods) mods #{ \with {} #})
       } \getMusic {} #'()
     #}))

% lyrics not tied to another voice
\registerTemplate lalily.Lyrics
#(define-music-function (parser location piece options)(list? list?)
   (let ((mods (assoc-get 'context-mods options #f #f))
         (lname (assoc-get 'context-name options (format "~A" piece) #f)))
     #{
       \new Lyrics = $lname \with{
         $(if (ly:context-mod? mods) mods #{ \with {} #})
       } { \getMusicDeep {} #'init-lyrics \getMusic #'() }
     #}))

% scale durations
\registerTemplate lalily.scale-dur
#(define-music-function (piece options)(list? list?)
   (let ((path (ly:assoc-get 'path options '(..) #f))
         (scale (ly:assoc-get 'scale options (cons 1 2) #t)))
     #{
       \rebaseMusic $scale \createScore #path
     #}
     ))
