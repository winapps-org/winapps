use crate::{Error, IntoResult, Result};
use std::process::Command;

pub(crate) fn execute_str(command: &str, message: &'static str) -> Result<String> {
    assert!(!command.is_empty());

    let (exec, args): (&str, Vec<&str>) = if command.contains(" ") {
        let mut split = command.split(" ");

        (
            split
                .next()
                .expect("There should always be at least one space command"),
            split.collect::<Vec<&str>>(),
        )
    } else {
        (message, vec![])
    };

    let child = Command::new(exec)
        .args(args)
        .spawn()
        .map_err(|source| Error::Command {
            message,
            source: source.into(),
            output: String::new(),
        })?;

    let result = child.wait_with_output().into_result()?;

    let stdout =
        String::from_utf8(result.stdout).expect("Commands should always return valid utf-8");

    let stderr =
        String::from_utf8(result.stderr).expect("Commands should always return valid utf-8");

    let output = format!("{stdout}\n{stderr}");

    result.status.exit_ok().map_err(|source| Error::Command {
        message,
        output: output.clone(),
        source: source.into(),
    })?;

    Ok(output)
}

pub(crate) fn execute(mut command: Command, message: &'static str) -> Result<String> {
    let child = command.spawn().map_err(|source| Error::Command {
        message,
        source: source.into(),
        output: String::new(),
    })?;

    let result = child.wait_with_output().into_result()?;

    let stdout =
        String::from_utf8(result.stdout).expect("Commands should always return valid utf-8");

    let stderr =
        String::from_utf8(result.stderr).expect("Commands should always return valid utf-8");

    let output = format!("{stdout}\n{stderr}");

    result.status.exit_ok().map_err(|source| Error::Command {
        message,
        output: output.clone(),
        source: source.into(),
    })?;

    Ok(output)
}
