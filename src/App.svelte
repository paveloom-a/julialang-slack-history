<script>
  // Data
	async function getChannels() {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-m/julialang-slack-history/history/channels.json`
    );
    channels = await res.json();
	}

	async function getNames() {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-m/julialang-slack-history/history/names.json`
    );
    names = await res.json();
	}

	async function getHistory(channel) {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-m/julialang-slack-history/history/messages/${channel}/${channel}.json`
    );
    history = await res.json();
	}

  let channels = getChannels();
  let names = getNames();

  let showHistory = false;
  let history = [];

  function channelClick(channel) {
    showHistory = true;
		history = getHistory(channel);
	}

  function test(el) {
    el.scrollTop = el.scrollHeight;
  }

  // Components
  import CollapseArrow from "./assets/CollapseArrow.svelte";
  import Hashtag from "./assets/Hashtag.svelte";
</script>

<style>
  @import url("https://fonts.googleapis.com/css2?family=Lato:wght@900&display=swap");

  #grid {
    display: grid;
    grid-template-columns: [start] max(17%, 220px) [sidebar] auto [end];
    height: 100%;
    width: 100%;
  }

  #grid > #history {
    display: grid;
    grid-column: sidebar;
    grid-template-rows: [start] 64px [channel-header] auto [end];
    overflow: hidden;
  }

  #grid > #history > #feed {
    -ms-overflow-style: none;
    display: flex;
    flex-direction: column;
    grid-row: channel-header;
    overflow-y: scroll;
    scrollbar-width: none;
  }

  #grid > #history > #feed::-webkit-scrollbar {
    display: none;
  }

  #grid > #history > #info {
    grid-row: channel-header;
  }

  #grid > #sidebar {
    background: #3f0e40;
    color: #ffffff;
    display: grid;
    grid-column: start;
    grid-template-rows: [start] 64px [sidebar-header] auto [end];
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
            <div class="channel" on:click={channelClick(channel)}>
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
    <div id="history">
      {#if showHistory}
          {#await history}
            <div id="info"><span class="text">Loading...</span></div>
          {:then}
            <div id="feed" use:test>
              {#each [...history.messages].reverse() as message}
                <div class="message">
                  <div class="text">{message.text}</div>
                </div>
              {/each}
            </div>
          {:catch}
            <div id="info">
              Nope.
            </div>
          {/await}
      {:else}
        <div id="info">
          hello?
        </div>
      {/if}
    </div>
  </div>
</body>
