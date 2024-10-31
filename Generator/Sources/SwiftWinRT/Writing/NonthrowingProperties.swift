import CodeWriters
import DotNetMetadata
import ProjectionModel

/// Writes a fatalerror'ing version of a property that delegates to the throwing accessors.
/// This allows the convenient "foo.prop = 42" syntax, at the expense of error handling.
/// The fatalerror'ing version exposes null results through implicitly unwrapped optionals.
internal func writeNonthrowingPropertyImplementation(
        property: Property, static: Bool, classDefinition: ClassDefinition? = nil,
        projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    // Nonthrowing properties are useful for the assignment syntax, so only relevant if we have a setter,
    // and Swift does not support set-only properties, so we require both accessors.
    guard try property.getter != nil, try property.setter != nil else { return }

    // Convert nullability representation from NullResult errors to implicitly unwrapped optionals (T!)
    var propertyType = try projection.toReturnType(property.type)
    let catchNullResult = projection.isNullAsErrorEligible(try property.type)
    if catchNullResult {
        propertyType = .optional(wrapped: propertyType, implicitUnwrap: true)
    }

    let selfKeyword = `static` ? "Self" : "self"

    try writer.writeComputedProperty(
        documentation: projection.getDocumentationComment(property, classDefinition: classDefinition),
        visibility: .public,
        static: `static`,
        name: Projection.toMemberName(property) + "_", // Disambiguate from throwing accessors
        type: propertyType,
        get: { writer in
            let output = writer.output
            output.write("try! ")
            if catchNullResult { output.write("NullResult.catch(") }
            output.write("\(selfKeyword).\(Projection.toMemberName(property))")
            if catchNullResult { output.write(")") }
        },
        set: { writer in
            writer.writeStatement("try! \(selfKeyword).\(Projection.toMemberName(property))(newValue)")
        })
}