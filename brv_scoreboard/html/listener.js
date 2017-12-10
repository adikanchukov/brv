$(function() {
  window.addEventListener('message', function(event) {
    var item = event.data;
    if (item.meta && item.meta == 'close') {
      $('#wrap, #global').fadeToggle(function() {
        $('table').html('');
      });
      return;
    }
    var buf = $('#wrap');
    buf.find('table').append('<tr class="heading"><th>ID</th><th>Name</th><th>Kills</th><th>Rank</th></tr>');
    buf.find('table').append(item.text);

    var buf = $('#global');
    buf.find('table').append('<tr class="heading"><th>Name</th><th>Wins</th><th>Kills</th><th>Games</th></tr>');
    buf.find('table').append(item.global);
    $('#wrap, #global').fadeToggle('fast');
  }, false);
});
