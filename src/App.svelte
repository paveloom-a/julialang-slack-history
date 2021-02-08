<script>
  "use strict";

  // Highlighting
  import hljs from "./libs/julia.highlight.min.js";

  function highlightBlock(el) {
    hljs.highlightBlock(el);
  }

  // Data
	async function getChannels() {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-a/julialang-slack-history/history/channels.json`
    );
    channels = await res.json();
	}

	async function getNames() {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-a/julialang-slack-history/history/names.json`
    );
    names = await res.json();
	}

	async function getHistory(channel) {
    const res = await fetch(
      `https://raw.githubusercontent.com/paveloom-a/julialang-slack-history/history/messages/${channel}/0.json`
    );
    history = await res.json();
	}

  let channels = getChannels();
  let names = getNames();

  let showHistory = false;
  let history = [];
  let users = [];
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
    users = [];
    history.messages.forEach(message => {
      message.hasOwnProperty('user') ? users.push(message.user) : users.push(message.bot_id);
    });
    let result = users.map(async(user) => {
      const res = await fetch(
        `https://raw.githubusercontent.com/paveloom-a/julialang-slack-history/history/users/${user}.json`
      );
      let info = await res.json();
      usersInfo[user] = info;
    });
    return Promise.all(result);
  }

  async function fetchAvatars(usersInfo) {
    let result = users.map(async(user) => {
      let res;
      if (user.startsWith('U')) {
        res = await fetch(
          usersInfo[user].profile.image_48, {mode: 'no-cors'}
        );
      } else {
        res = await fetch(
          usersInfo[user].icons.image_48, {mode: 'no-cors'}
        );
      }
      return await res.blob();
    });
    return Promise.all(result);
  }

  function formatText(el) {
    // Code filters
    el.innerHTML = el.textContent.replace(
      /```([\s\S]+?)```/g,
      '<pre><code language="julia">$1</code></pre>'
    ).replace(
      /`([\s\S]+?)`/g,
      '<span><code language="julia">$1</code></span>'
    // Mentions
    ).replace(
      /<@(.*)>/g,
      function (match, capture) {
        if (capture in usersInfo) {
          return '<span class="mention">@' + usersInfo[capture].name + '</span>';
        } else {
          return match;
        }
      }
    );
    let code_elements = el.getElementsByTagName('code');
    for (let item of code_elements) {
      hljs.highlightBlock(item);
    };
  }

  // Components
  import CollapseArrow from "./assets/CollapseArrow.svelte";
  import Hashtag from "./assets/Hashtag.svelte";
</script>

<style type="text/scss">
  @import url("https://fonts.googleapis.com/css2?family=Lato:wght@400;900&display=swap");

  #grid {
    display: grid;
    grid-template-columns: [start] 260px [sidebar] auto [end];
    height: 100%;
    width: 100%;
    > #history {
      display: grid;
      grid-column: sidebar;
      grid-template-rows: [start] 64px [channel-header] auto [end];
      overflow: hidden;
      position: relative;
      &::after {
        background-image: linear-gradient(to top, #ffffff, rgba(0,0,0,0));
        bottom: 0;
        content: "";
        grid-row: channel-header;
        height: 24px;
        position: absolute;
        width: 100%;
      }
      &::before {
        background-image: linear-gradient(to bottom, #ffffff, rgba(0,0,0,0));
        content: "";
        grid-row: channel-header;
        height: 24px;
        position: absolute;
        top: 0;
        width: 100%;
        z-index: 1;
      }
      > #feed {
        -ms-overflow-style: none;
        display: flex;
        flex-direction: column;
        grid-row: channel-header;
        overflow-y: scroll;
        padding: 24px 28px;
        scrollbar-width: none;
        &::-webkit-scrollbar {
          display: none;
        }
        > .message {
          display: grid;
          grid-template-columns: [start] 36px [avatar-column] auto [end];
          > .avatar_column {
            grid-column: start;
            > img {
              max-width: 100%;
              padding: 12px 0 0 0;
            }
          }
          > .body {
            grid-column: avatar-column;
            padding: 8px 12px;
            overflow-x: hidden;
            > .name {
              font-weight: bold;
            }
            > .text {
              overflow-wrap: anywhere;
              > :global(.mention) {
                background: rgba(29,155,209,.1);
                color: rgba(18,100,163,1);
                padding: 0 2px 1px 2px;
                border-radius: 3px;
              }
            }
          }
        }
      }
      > #header {
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
      > #info {
        grid-row: start / end;
        margin: auto;
        text-align: center;
        #text {
          font-size: 24px;
        }
      }
    }
    > #sidebar {
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
      &::after {
        background-image: linear-gradient(to top, #3F0E40, rgba(0,0,0,0));
        bottom: 0;
        content: "";
        grid-row: sidebar-header;
        height: 24px;
        pointer-events: none;
        position: absolute;
        width: 100%;
      }
      &::before {
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
      > #header {
        align-items: center;
        border-bottom: 1px solid rgb(82, 38, 83);
        display: flex;
        grid-row: start;
        padding: 0 19px 0 16px;
      }
      > #channels {
        -ms-overflow-style: none;
        display: flex;
        fill: #ffffff;
        flex-direction: column;
        grid-row: sidebar-header;
        overflow-y: scroll;
        padding: 0 19px 28.4px 16px;
        scrollbar-width: none;
        &::-webkit-scrollbar {
          display: none;
        }
        > #header {
          margin: 16px 0px;
        }
        > .channel {
          cursor: pointer;
          margin-left: 10px;
          padding: 0 0 4px 0;
          position: relative;
          z-index: 0;
          &:hover .channel-background {
            display: block;
          }
          > .channel-background {
            display: none;
            background-color: rgb(53, 13, 54);
            height: 100%;
            left: -26px;
            position: absolute;
            width: calc(16px + 10px + 100% + 19px);
            z-index: -1;
          }
          > .channel-background.selected {
            display: block;
            background-color: #1164A3;
          }
          > .content {
            display: flex;
            margin-top: 3px;
            min-width: 0;
            > .icon {
              display: flex;
            }
            > .text {
              overflow: hidden;
              text-overflow: ellipsis;
              white-space: nowrap;
            }
          }
        }
      }
    }
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
              {#await fetchAvatars(usersInfo)}
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
                        {#if message.hasOwnProperty('user')}
                          <img src={usersInfo[message.user].profile.image_48}>
                        {:else}
                          <img src={usersInfo[message.bot_id].icons.image_48}>
                        {/if}
                      </div>
                      <div class="body">
                        {#if message.hasOwnProperty('user')}
                          <span class="name">
                            {usersInfo[message.user].real_name}
                          </span>
                        {:else}
                          <span class="name">
                            {usersInfo[message.bot_id].name}
                          </span>
                        {/if}
                        <div class="text" use:formatText>{message.text}</div>
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
