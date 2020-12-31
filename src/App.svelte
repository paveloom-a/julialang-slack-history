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

  let selected = "";

  function channelClick(channel) {
    showHistory = true;
    selected = channel;
		history = getHistory(channel);
	}

  function scrollDown(el) {
    el.scrollTop = el.scrollHeight + 200;
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
      usersInfo[user] = info.user;
    });
    return Promise.all(result);
  }

  async function fetchAvatars(history, usersInfo) {
    let users = [];
    history.messages.forEach(message => {
      message.hasOwnProperty('user') && users.push(message.user);
    });
    let result = users.map(async(user) => {
      const res = await fetch(
        usersInfo[user].profile.image_48, {mode: 'no-cors'}
      );
      let avatar = await res.blob();
    });
    return Promise.all(result);
  }

  // Components
  import CollapseArrow from "./assets/CollapseArrow.svelte";
  import Hashtag from "./assets/Hashtag.svelte";
</script>

<style>
  @import url("https://fonts.googleapis.com/css2?family=Lato:wght@400;900&display=swap");

  #grid {
    display: grid;
    grid-template-columns: [start] 260px [sidebar] auto [end];
    height: 100%;
    width: 100%;
  }

  #grid > #history {
    display: grid;
    grid-column: sidebar;
    grid-template-rows: [start] 64px [channel-header] auto [end];
    overflow: hidden;
    position: relative;
  }

  #grid > #history::after {
    background-image: linear-gradient(to top, #ffffff, rgba(0,0,0,0));
    bottom: 0;
    content: "";
    grid-row: channel-header;
    height: 24px;
    position: absolute;
    width: 100%;
  }

  #grid > #history::before {
    background-image: linear-gradient(to bottom, #ffffff, rgba(0,0,0,0));
    content: "";
    grid-row: channel-header;
    height: 24px;
    position: absolute;
    top: 0;
    width: 100%;
    z-index: 1;
  }

  #grid > #history > #feed {
    -ms-overflow-style: none;
    display: flex;
    flex-direction: column;
    grid-row: channel-header;
    overflow-y: scroll;
    padding: 24px 28px;
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

  #grid > #history > #feed > .message > .avatar_column > img {
    max-width: 100%;
    padding: 12px 0 0 0;
  }

  #grid > #history > #feed > .message > .body {
    grid-column: avatar-column;
    padding: 8px 12px;
  }

  #grid > #history > #feed > .message > .body > .name {
    font-weight: bold;
  }

  #grid > #history > #feed > .message > .body > .text {
    font-weight: regular;
  }

  #grid > #history > #header {
    -webkit-touch-callout: none;
    -webkit-user-select: none;
    -khtml-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    align-items: center;
    border-bottom: 1px solid rgba(29,28,29,.13);
    display: flex;
    font-weight: bold;
    grid-row: start;
    padding: 0 19px 0 16px;
    user-select: none;
  }

  #grid > #history > #info {
    grid-row: start / end;
    margin: auto;
    text-align: center;
  }

  #grid > #history > #info > #text {
    font-size: 24px;
  }

  #grid > #sidebar {
    -webkit-touch-callout: none;
    -webkit-user-select: none;
    -khtml-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    background: #3f0e40;
    color: #ffffff;
    display: grid;
    font-weight: bold;
    grid-column: start;
    grid-template-rows: [start] 64px [sidebar-header] auto [end];
    overflow: hidden;
    position: relative;
    user-select: none;
  }

  #grid > #sidebar::after {
    background-image: linear-gradient(to top, #3F0E40, rgba(0,0,0,0));
    bottom: 0;
    content: "";
    grid-row: sidebar-header;
    height: 24px;
    pointer-events: none;
    position: absolute;
    width: 100%;
  }

  #grid > #sidebar::before {
    background-image: linear-gradient(to bottom, #3F0E40, rgba(0,0,0,0));
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
    cursor: pointer;
    margin-left: 10px;
    padding: 0 0 4px 0;
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

  #grid > #sidebar > #channels > .channel > .channel-background.selected {
    display: block;
    background-color: #1164A3;
  }

  #grid > #sidebar > #channels > .channel > .content {
    display: flex;
    margin-top: 3px;
    min-width: 0;
  }

  #grid > #sidebar > #channels > .channel > .content > .icon {
    display: flex;
  }

  #grid > #sidebar > #channels > .channel > .content > .text {
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
                  <div
                    class="channel-background"
                    class:selected="{selected === channel}">
                  </div>
                  <div class="content">
                    <div class="icon"><Hashtag /></div>
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
            <div id="info">
              <span id="text">
                Loading history...
              </span>
            </div>
          {:then}
            {#await getUsersInfo(history)}
              <div id="info">
                <span id="text">
                  Loading users...
                </span>
              </div>
            {:then}
              {#await fetchAvatars(history, usersInfo)}
                <div id="info">
                  <span id="text">
                    Loading avatars...
                  </span>
                </div>
              {:then}
                <div id="header">#{names[selected]}</div>
                <div id="feed" use:scrollDown>
                  {#each history.messages as message}
                    <div class="message">
                      <div class="avatar_column">
                        <img
                          src={usersInfo[message.user].profile.image_48}
                          alt="${message.user}'s avatar"
                        >
                      </div>
                      <div class="body">
                        {#if message.hasOwnProperty('user')}
                          <span class="name">
                            {usersInfo[message.user].real_name}
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
            {/await}
          {:catch}
            <div id="info">
              <span id="text">
                Whoops! Looks like this channel doesn't<br>
                have any history stored yet.
              </span>
            </div>
          {/await}
      {:else}
        <div id="info">
          <span id="text">
            Choose a channel to proceed.
          </span>
        </div>
      {/if}
    </div>
  </div>
</body>
