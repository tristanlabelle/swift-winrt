import CodeWriters
import Collections
import DotNetMetadata
import ProjectionModel
import WindowsMetadata

internal func writeCAbiFile(module: SwiftProjection.Module, toPath path: String) throws {
    let cHeaderWriter = CSourceFileWriter(output: FileTextOutputStream(path: path, directoryCreation: .ancestors))

    // Write includes
    cHeaderWriter.writeInclude(pathSpec: "_Core.h", kind: .doubleQuotes)
    for referencedModule in module.references {
        guard !referencedModule.isEmpty else { continue }
        cHeaderWriter.writeInclude(pathSpec: "\(referencedModule.name).h", kind: .doubleQuotes)
    }

    // Declare enums
    for enumDefinition in try getSortedEnums(module: module) {
        try CAbi.writeEnumTypedef(enumDefinition, to: cHeaderWriter)
    }

    // Declare structs in an order that support nesting dependencies.
    for structDefinition in try getSortedStructs(module: module) {
        try CAbi.writeStruct(structDefinition, to: cHeaderWriter)
    }

    // Write all interfaces and delegates
    let interfaces = try getSortedInterfaces(module: module)
    for interface in interfaces {
        try CAbi.writeForwardDecl(type: interface, to: cHeaderWriter)
    }

    for interface in interfaces {
        guard interface.definition.fullName != "Windows.Foundation.IReference`1" else { continue }
        try CAbi.writeCOMInterface(interface.definition, genericArgs: interface.genericArgs, to: cHeaderWriter)
    }
}

fileprivate func getSortedEnums(module: SwiftProjection.Module) throws -> [EnumDefinition] {
    var enumDefinitions = [EnumDefinition]()
    for typeDefinition in module.typeDefinitions {
        guard let enumDefinition = typeDefinition as? EnumDefinition else { continue }
        enumDefinitions.append(enumDefinition)
    }

    enumDefinitions.sort { $0.fullName < $1.fullName }
    return enumDefinitions
}

// Gets the module's structs in an order so that nested structs appear before their containers.
fileprivate func getSortedStructs(module: SwiftProjection.Module) throws -> [StructDefinition] {
    // Create an initial deterministic ordering of structs
    var sortedByFullName = [StructDefinition]()
    for typeDefinition in module.typeDefinitions {
        guard let structDefinition = typeDefinition as? StructDefinition else { continue }
        sortedByFullName.append(structDefinition)
    }

    sortedByFullName.sort { $0.fullName < $1.fullName }

    // Sort structs so that nested structs appear before their containers
    var visited = Set<StructDefinition>()
    var sorted = [StructDefinition]()

    func visit(_ structDefinition: StructDefinition) throws {
        guard visited.insert(structDefinition).inserted else { return }

        for field in structDefinition.fields {
            if case .bound(let type) = try field.type,
                    let structDefinition = type.definition as? StructDefinition,
                    module.hasTypeDefinition(structDefinition) {
                try visit(structDefinition)
            }
        }

        sorted.append(structDefinition)
    }

    for structDefinition in sortedByFullName { try visit(structDefinition) }

    return sorted
}

fileprivate func getSortedInterfaces(module: SwiftProjection.Module) throws -> [BoundType] {
    var interfacesByMangledName = OrderedDictionary<String, BoundType>()

    // Add nongeneric type definitions
    for typeDefinition in module.typeDefinitions {
        guard typeDefinition.isReferenceType else { continue }
        guard !(typeDefinition is ClassDefinition) else { continue }
        guard typeDefinition.genericArity == 0 else { continue }

        let type = typeDefinition.bindType()
        let mangledName = try CAbi.mangleName(type: type)
        interfacesByMangledName[mangledName] = type
    }

    // Add closed generic type instanciations
    for (typeDefinition, instanciations) in module.genericInstantiationsByDefinition {
        // IReference<T> is implemented generically in the support module.
        if typeDefinition.namespace == "Windows.Foundation", typeDefinition.name == "IReference`1" { continue }
        for genericArgs in instanciations {
            let type = typeDefinition.bindType(genericArgs: genericArgs)
            let mangledName = try CAbi.mangleName(type: type)
            interfacesByMangledName[mangledName] = type
        }
    }

    interfacesByMangledName.sort { $0.key < $1.key }
    return Array(interfacesByMangledName.values)
}
