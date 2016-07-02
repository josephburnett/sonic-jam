Sonic Jam is a loop-oriented, multi-player framework for making music with [Sonic Pi](http://sonic-pi.net/).

![Sonic Jam](doc/sonic-jam.png)

# Quick Start

1. Start [Sonic Pi](http://sonic-pi.net/).
2. Download and run Sonic Jam ([linux](https://github.com/josephburnett/sonic-jam/blob/v0.1/release/sonic-jam-linux)) ([osx](https://github.com/josephburnett/sonic-jam/blob/v0.1/release/sonic-jam-osx)).
3. Open http://localhost:8080

# How to Jam

Click on a cell to toggle it on (`1`) and off (`0`).

![Turning on a cell](doc/how-to-jam-cell-on.png)

Click on the properties icon `{..}` at the end of a track to add a synth or sample.  It will be played when the cursor is on a cell which is on.

![Selecting a sample](doc/how-to-jam-select-sample.png)

Click on the track builder `[+ 8]` to add new tracks.  Pro tip: click on the `+` to show more options; click on the `8` to add another track of the same length.

![Add a track](doc/how-to-jam-add-track.png)

Click on the properties icon `{..}` at the top of a grid to change the beats-per-sample (`bpc`) and to change the grid width (`+/-`).

![Changing grid properties](doc/how-to-jam-grid-properties.png)

You can add parameters (`params`) to a synth or sample in the track properties.  Look at the Sonic Pi help pages for each synth or sample to see supported parameters.

![Adding track params](doc/how-to-jam-add-params.png)

You can add effects (`fx`) to a track in the track properties.  Effects are applied in the order in which they are added.  You can parameterize effects, just like synths and samples.  See Sonic Pi help pages for supported parameters.

![Adding fx and fx params](doc/how-to-jam-add-fx.png)

## Sub-grids

In addition to synth and sample tracks, you can create grid tracks which contain an entirely separate sub-grid.  The sub-grid will be played when the cursor is at a cell which is on.

![A sub-grid](doc/how-to-jam-sub-grid.png)

Sub-grids tracks have their own parameters and effects.  However the tracks in a sub-grid can inherit some parameters and effects from their containing (parent) track.  For example, a parent track which has a sub-grid type (`grid-type`) of `sample` will cause all tracks in the sub-grid to be interpreted as sample tracks.  Parameters which are set on the parent track, such as `pitch`, will apply to all the sub-grid tracks (unless they have an `pitch` parameter of their own.)

## Lambdas

Parameters are what make Sonic Pi synths and samples interesting to play with.  In addition to providing a scalar value, you can provide a function (lambda) which will be evaluated each time the track is played.  Any parameter which starts with the `\` character is interpreted as a lambda.

The lambda could do anything from returning a random value to increasing its value over time.  The evaluation context is the same as the Sonic Pi editor except that two additional values are in scope: 1) `beat_index` which is the zero-based index at which the cursor (beat) is in the track and 2) `row_index` which is the zero-based index at which the track is in the grid.  `beat_index` can be used to change the parameters of a track over time, restarting at the end of each loop.  `row_index` can be used to implement something like a piano roll (see Patterns below.)

### Twinkle, Twinkle Little Star

#### Organized into two parts

![Twinkle, twinkle little star](doc/how-to-jam-complex-sub-grid-1.png)

#### Part 1

![Twinkle, twinkle little star](doc/how-to-jam-complex-sub-grid-2.png)

#### Part 2

![Twinkle, twinkle little star](doc/how-to-jam-complex-sub-grid-3.png)

Pro tip: right-click on a cell to make a synth sustain (`2`, `3`, ...)

# Patterns

## The piano roll

When building a melody it is useful to have the tracks of a grid represent the notes of a scale.  This can be done by parameterizing a parent track with a lambda which calculates `pitch` based on `row_index`.

![A piano roll](doc/patterns-piano-roll.png)

## Multiplayer jamming

Sonic Jam is built from the ground-up to support multiple players.  For example, two players can jam on the same instance by visiting the same URL in their browser.  Changes to one will immediately take effect in the other.

Sub-grids can be used to give each player their own space to work in.  The players can take turns (call-and-response) or play together.

#### Together

![Multiplayer subgrids together](doc/patterns-multiplayer-together.png)

#### Call and response

![Multiplayer subgrids call and response](doc/patterns-multiplayer-call-response.png)

# Architecture

## Data model and state

## Components
