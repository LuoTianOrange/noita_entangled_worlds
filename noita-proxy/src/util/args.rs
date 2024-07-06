use argh::FromArgs;

#[derive(FromArgs, PartialEq, Debug)]
/// Noita proxy.
pub struct Args {
    /// noita launch command that will be used.
    #[argh(option)]
    pub launch_cmd: Option<String>,
    #[argh(option)]
    /// adjust ui scale.
    pub ui_zoom_factor: f32,
}