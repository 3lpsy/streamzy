<template>
    <div>
        <video
            ref="videoPlayer"
            width="600"
            height="300"
            class="video-js vjs-default-skin"
            controls
        ></video>
    </div>
</template>

<script>
import videojs from "video.js";
import "dashjs";
import "videojs-contrib-dash";

export default {
    name: "VideoPlayer",
    props: {
        options: {
            type: Object,
            default() {
                return {
                    controls: true,
                    sources: [
                        {
                            src: "http://stream.fgsec.io/streams/hello.mpd",
                            type: "application/dash+xml"
                        }
                    ]
                };
            }
        }
    },
    data() {
        return {
            player: null
        };
    },
    mounted() {
        this.player = videojs(
            this.$refs.videoPlayer,
            this.options,
            function onPlayerReady() {
                console.log("onPlayerReady", this);
            }
        );
    },
    beforeDestroy() {
        if (this.player) {
            this.player.dispose();
        }
    }
};
</script>