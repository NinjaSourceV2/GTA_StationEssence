const vFuel = document.querySelector(".progress-fuel");

function updateProgressfuel(fuel, value) {
    fuel.querySelector(".progressfill").style.width = `${value}%`;
}

function display(bool) {
    if (bool) {
        $(".progress-fuel").show();
    } else {
        $(".progress-fuel").hide();
    }
}

$(function() {

    display(false)

    window.addEventListener('message', function(event) {
        if (event.data.type == "vfuel") {
            (event.data.data_hudOn ? display(true) : display(false))
            updateProgressfuel(vFuel, event.data.data_newFuel)
        }
    })
})