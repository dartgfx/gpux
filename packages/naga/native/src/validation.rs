use crate::results::{make_ok_validation, make_single_error, NagaValidationResult};

pub(crate) fn validate_module(
    module: &naga::Module,
    capabilities: naga::valid::Capabilities,
    source: &str,
) -> NagaValidationResult {
    match validate_module_info(module, capabilities, source) {
        Ok(_) => make_ok_validation(),
        Err(result) => result,
    }
}

pub(crate) fn validate_module_info(
    module: &naga::Module,
    capabilities: naga::valid::Capabilities,
    source: &str,
) -> Result<naga::valid::ModuleInfo, NagaValidationResult> {
    let mut validator =
        naga::valid::Validator::new(naga::valid::ValidationFlags::all(), capabilities);
    validator
        .subgroup_stages(naga::valid::ShaderStages::all())
        .subgroup_operations(naga::valid::SubgroupOperationSet::all());

    validator
        .validate(module)
        .map_err(|error| validation_error_to_result(&error, source))
}

fn validation_error_to_result(
    error: &naga::WithSpan<naga::valid::ValidationError>,
    source: &str,
) -> NagaValidationResult {
    let message = format!("{}", error);
    let (offset, length) = error
        .spans()
        .next()
        .map(|(span, _)| {
            let loc = span.location(source);
            (loc.offset as i32, loc.length as i32)
        })
        .unwrap_or((-1, -1));

    make_single_error(&message, offset, length)
}
