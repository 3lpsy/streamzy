# A Pretty Lame Self Hosted Streaming Service

This project contains:

- A small auth server for authenticating rtmp publishing
- A nginx server to publish rtmp streams to
- A nginx server to server a simple html5/js video player
- An automated terraform build

The latency is really bad with dash and hls. I think that's just the nature of the technology (lmk if you have ideas for improving the delay). It's actually just easier to use vlc to read rtmp if you need to do something like screen sharing.
