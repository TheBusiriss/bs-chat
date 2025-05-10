# bs-chat

A stable FiveM chat resource with:

- `/me`, `/do`, `/ooc` (and prefixless: `me waves`, `do looks around`)
- `/emsc` and `/pdc` channels (job-gated)
- Error/system/server messages
- Client-side distance filtering for roleplay commands

## Installation

1. Drop `bs-chat/` into your `resources/`.
2. Add `ensure bs-chat` to your `server.cfg`.
3. Make sure you have `qb-core` installed.

## Configuration

Edit `config.lua` to adjust distances, jobs and message types.

## Usage

Any chat input:

- If first word matches a key in `Config.MessageTypes`, it’s treated as that command (slash optional).
- Otherwise it’s normal chat.
