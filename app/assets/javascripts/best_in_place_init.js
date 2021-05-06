
jQuery(document).on('best_in_place:error', function (event, request, error) {
  var is_json = false
  if (is_json) {
    // Display all error messages from server side validation
    jQuery.each(jQuery.parseJSON(request.responseText), function (index, value) {
      if (typeof value === "object") {value = index + " " + value.toString(); }
      Flash.error(value);
    });
  } else {
    Flash.error(request.responseText)
  }
});

document.addEventListener("turbolinks:load", function() {
  $(".best_in_place").best_in_place();
  $('.best_in_place').bind("ajax:success", function () {$(this).closest('td').effect('highlight'); });
  $('.best_in_place').bind("ajax:error", function () {$(this).closest('td').effect('bounce'); });
  $('.best_in_place[data-reload-on-success]').bind("ajax:success", function () {NProgress.start(); location.reload();});
});

