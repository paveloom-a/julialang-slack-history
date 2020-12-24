<script>
  import summary from "./history/channels.json";
  const channels = Object.keys(summary);

  import CollapseArrow from "./assets/CollapseArrow.svelte";
  import Hashtag from "./assets/Hashtag.svelte";
</script>

<style>
  @import url('https://fonts.googleapis.com/css2?family=Lato:wght@900&display=swap');

  .grid {
    display: grid;
    grid-template-columns: [start] 25% [sidebar] auto [end];
    height: 100%;
    width: 100%;
  }

  .grid > .sidebar {
    background: #3f0e40;
    color: #ffffff;
    display: grid;
    grid-column: start;
    grid-template-rows: [start] 64px [sidebar-header] auto [end];
    overflow: hidden;
  }

  .grid > .sidebar > .header {
    align-items: center;
    border-bottom: 1px solid rgb(82, 38, 83);
    display: flex;
    grid-row: start;
    padding: 0 19px 0 16px;
  }

  .grid > .sidebar > .channels {
    align-items: left;
    color: #ffffff;
    display: flex;
    fill: #ffffff;
    flex-direction: column;
    grid-row: sidebar-header;
    overflow-y: scroll;
    padding: 0 19px 0 16px;
  }

  .grid > .sidebar > .channels > .header {
    margin: 16px 0px;
  }

  .grid > .sidebar > .channels > .channel {
    display: flex;
    align-items: center;
    margin-left: 10px;
    min-width: 0;
  }

  .grid > .sidebar > .channels > .channel > span.text {
    margin-bottom: 5px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
</style>

<body>
  <div class="grid">
    <div class="sidebar">
      <div class="header">
        <span>Julia</span>
      </div>
      <div class="channels">
        <div class="header">
          <span class="icon"><CollapseArrow />Channels</span>
        </div>
        {#each channels as channel}
          <div class="channel">
            <span class="icon"><Hashtag /></span>
            <span class="text">{summary[channel]}</span>
          </div>
        {/each}
      </div>
    </div>
  </div>
</body>
