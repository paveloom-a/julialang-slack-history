<script>
  // Data
	async function getChannels() {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-m/julialang-slack-history/gh-pages/src/history/channels.json`
    );
    channels = await res.json();
	}

	async function getNames() {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-m/julialang-slack-history/gh-pages/src/history/names.json`
    );
    names = await res.json();
	}

  let channels = getChannels();
  let names = getNames();

  function handleClick() {
		alert('Hello there!')
	}

  // Components
  import CollapseArrow from "./assets/CollapseArrow.svelte";
  import Hashtag from "./assets/Hashtag.svelte";
</script>

<style>
  @import url("https://fonts.googleapis.com/css2?family=Lato:wght@900&display=swap");

  #grid {
    display: grid;
    grid-template-columns: [start] 17% [sidebar] auto [end];
    height: 100%;
    width: 100%;
  }

  #grid > #sidebar {
    background: #3f0e40;
    color: #ffffff;
    display: grid;
    grid-column: start;
    grid-template-rows: [start] 64px [sidebar-header] auto [end];
    min-width: 220px;
    overflow: hidden;
    position: relative;
  }

  #grid > #sidebar::after {
    background-image: linear-gradient(to top, #3F0E40, rgba(63,14,64,0));
    bottom: 0;
    content: "";
    grid-row: sidebar-header;
    height: 24px;
    pointer-events: none;
    position: absolute;
    width: 100%;
  }

  #grid > #sidebar::before {
    background-image: linear-gradient(to bottom, #3F0E40, rgba(63,14,64,0));
    content: "";
    grid-row: sidebar-header;
    height: 24px;
    pointer-events: none;
    position: absolute;
    top: 0;
    width: 100%;
    z-index: 1;
  }

  #grid > #sidebar > #header {
    align-items: center;
    border-bottom: 1px solid rgb(82, 38, 83);
    display: flex;
    grid-row: start;
    padding: 0 19px 0 16px;
  }

  #grid > #sidebar > #channels {
    -ms-overflow-style: none;
    display: flex;
    fill: #ffffff;
    flex-direction: column;
    grid-row: sidebar-header;
    overflow-y: scroll;
    padding: 0 19px 28.4px 16px;
    scrollbar-width: none;
  }

  #grid > #sidebar > #channels::-webkit-scrollbar {
    display: none;
  }

  #grid > #sidebar > #channels > #header {
    margin: 16px 0px;
  }

  #grid > #sidebar > #channels > .channel {
    align-items: center;
    cursor: pointer;
    display: flex;
    margin-left: 10px;
    min-width: 0;
    padding: 3px 0;
    position: relative;
    z-index: 0;
  }

  #grid > #sidebar > #channels > .channel:hover .channel-background {
    display: block;
  }

  #grid > #sidebar > #channels > .channel > .channel-background {
    display: none;
    background-color: rgb(53, 13, 54);
    height: 100%;
    left: -26px;
    position: absolute;
    width: calc(16px + 10px + 100% + 19px);
    z-index: -1;
  }

  #grid > #sidebar > #channels > .channel > span.text {
    height: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
</style>

<body>
  <div id="grid">
    <div id="sidebar">
      <div id="header"><span>Julia</span></div>
      <div id="channels">
        <div id="header">
          <span class="icon"><CollapseArrow />Channels</span>
        </div>
        {#await names}
          <div class="channel"><span class="text">Loading...</span></div>
        {:then}
          {#each channels as channel}
            <div class="channel" on:click={handleClick}>
                <div class="channel-background"></div>
                <span class="icon"><Hashtag /></span>
                <span class="text">{names[channel]}</span>
            </div>
          {/each}
        {:catch}
          <div class="channel">
            <span class="text">
              Couldn't load the data.<br><br>
              Check your Internet<br>
              connection.
            </span>
          </div>
        {/await}
      </div>
    </div>
  </div>
</body>
