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
      `https://raw.githubusercontent.com/paveloom-m/julialang-slack-history/history/messages/${channel}/0.json`
    );
    history = await res.json();
	}

  let channels = getChannels();
  let names = getNames();

  let showHistory = false;
  let history = [];
  let usersInfo = [];

  function channelClick(channel) {
    showHistory = true;
		history = getHistory(channel);
	}

  function scrollDown(el) {
    el.scrollTop = el.scrollHeight;
  }

  async function getUsersInfo(history) {
    let users = [];
    history.messages.forEach(message => {
      message.hasOwnProperty('user') && users.push(message.user);
    });
    let result = users.map(async(user) => {
      const res = await fetch(
        `https://raw.githubusercontent.com/paveloom-m/julialang-slack-history/history/users/${user}.json`
      );
      let info = await res.json();
      usersInfo[user] = info;
    })
    return Promise.all(result);
  }

  // Components
  import CollapseArrow from "./assets/CollapseArrow.svelte";
  import Hashtag from "./assets/Hashtag.svelte";
</script>

<style>
  @import url("https://fonts.googleapis.com/css2?family=Lato:wght@300;@900&display=swap");

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

  #grid > #history > #feed > .message {
    display: grid;
    grid-template-columns: [start] 36px [avatar-column] auto [end];
  }

  #grid > #history > #feed > .message > .avatar_column {
    grid-column: start;
  }

  #grid > #history > #feed > .message > .body {
    grid-column: avatar-column;
  }

  #grid > #history > #feed > .message > .body > .name {
    font-weight: bold;
  }

  #grid > #history > #feed > .message > .body > .text {
    font-weight: lighter;
  }

  #grid > #history > #info {
    grid-row: channel-header;
  }

  #grid > #sidebar {
    background: #3f0e40;
    color: #ffffff;
    display: grid;
    font-weight: bold;
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
    padding: 2px 0;
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

  #grid > #sidebar > #channels > .channel > .content {
    display: flex;
    margin-top: 3px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  #grid > #sidebar > #channels > .channel > .content > span.text {
    margin-top: 1.5px;
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
        {#await channels}
          <div class="channel">
            <div class="content">
              <span class="text">Loading channels...</span>
            </div>
          </div>
        {:then}
          {#await names}
            <div class="channel">
              <div class="content">
                <span class="text">Loading names...</span>
              </div>
            </div>
          {:then}
            {#each channels as channel}
              <div class="channel" on:click={channelClick(channel)}>
                  <div class="channel-background"></div>
                  <div class="content">
                    <span class="icon"><Hashtag /></span>
                    <span class="text">{names[channel]}</span>
                  </div>
              </div>
            {/each}
          {:catch}
            <div class="channel">
              <div class="content">
                <span class="text">
                  Couldn't load the data.<br><br>
                  Check your Internet<br>
                  connection.
                </span>
              </div>
            </div>
          {/await}
        {/await}
      </div>
    </div>
    <div id="history">
      {#if showHistory}
          {#await history}
            <div id="info"><span class="text">Loading history...</span></div>
          {:then}
            {#await getUsersInfo(history)}
              <div id="info"><span class="text">Loading users...</span></div>
            {:then}
              <div id="feed" use:scrollDown>
                {#each history.messages as message}
                  <div class="message">
                    <div class="avatar_column"></div>
                    <div class="body">
                      {#if message.hasOwnProperty('user')}
                        <span class="name">
                          {usersInfo[message.user].user.real_name}
                        </span>
                      {:else if message.hasOwnProperty('bot_id')}
                        <span class="name">Bot</span>
                      {:else}
                        <span class="name">Else</span>
                      {/if}
                      <div class="text">{message.text}</div>
                    </div>
                  </div>
                {/each}
              </div>
            {/await}
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
