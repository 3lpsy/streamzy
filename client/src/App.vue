<template>
    <div id="app">
        <!-- <img alt="Vue logo" src="./assets/logo.png"> -->
        <StreamCapture/>
    </div>
</template>

<script>
import StreamCapture from "./components/StreamCapture.vue";

export default {
    name: "app",
    components: {
        StreamCapture
    }
};
</script>

<style lang="scss">
@import "~video.js/dist/video-js.css";

#app {
    font-family: "Avenir", Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
    margin-top: 60px;
}
</style>
