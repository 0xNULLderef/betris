use gilrs::{Axis, Button, Event, EventType, Gilrs};

fn main() {
    let mut gilrs = Gilrs::new().unwrap();

    // Iterate over all connected gamepads
    /*
    for (_id, gamepad) in gilrs.gamepads() {
        println!("{} is {:?}", gamepad.name(), gamepad.power_info());
    }
    */

    loop {
        // Examine new events
        while let Some(Event { event, .. }) = gilrs.next_event() {
            match event {
                EventType::ButtonPressed(button, _code) => match button {
                    Button::South => println!("q"),
                    Button::East => println!("e"),
                    _ => {}
                },
                EventType::AxisChanged(axis, num, _code) => {
                    match axis {
                        Axis::LeftStickX => {
                            match num {
                                1.0 => println!("d"),  // right
                                -1.0 => println!("a"), // left
                                _ => {}
                            }
                        }
                        Axis::LeftStickY => {
                            match num {
                                1.0 => println!("w"),  // up
                                -1.0 => println!("s"), // down
                                _ => {}
                            }
                        }
                        _ => {}
                    }
                }
                _ => {}
            }
            //println!("{:?}", event);
        }

        /*
        // You can also use cached gamepad state
        if let Some(gamepad) = active_gamepad.map(|id| gilrs.gamepad(id)) {
            if gamepad.is_pressed(Button::South) {
                println!("Button South is pressed (XBox - A, PS - X)");
            }
        }
        */
    }
}
