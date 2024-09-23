# Kombo

**Kom**ga + Ko**bo**

## What is this?

A docker container that monitors your Komga comics / manga / ebooks library and converts from CBZ/CBR to EPUB automatically.

## My use-case

>I personally couldn't find anything that worked with my setup, my setup is this and if yours is similar it'll likely benefit you too :)

1. I have mylar3 snatching my comics which puts them in my main Comics library
2. I then have Komga hosting my Comics for me to read. I have historically read my comics over OPDS on my iPad using Panels but I just got a Kobo Libra Colour :D
3. I want to use the native Kobo Sync feature that Komga uses

This is where the catch is; Kobo Sync with Komga only works on _epubs_. Comics are commonly found in CBZ/CBR formats.

There is a tool, [kcc](https://github.com/ciromattia/kcc) that will convert CBZ/CBR to EPUB.

This container is essentially a script that wraps KCC and performs the conversion automatically.

## Docker Compose

Simply create a `docker-compose.yml` like the one in the repo

Set `PROFILE` to a value supported from [here](https://github.com/ciromattia/kcc?tab=readme-ov-file#profiles)

Set `FORMAT` to a format of your choosing (e.g. `EPUB`, case sensitive)

There are three volumes required `/input`, `/output` and `/config`. `/input` is for your incoming books, `/output` is where your converted books will be saved and `/config` is for working files. `/config` MUST be specified for any persistence otherwise any time the docker container is started, it will convert ALL the books in `/input`.
