import SwiftSyntax
import SwiftBasicFormat
import SwiftSyntaxBuilder
import DotNetMD

let namespace = CommandLine.arguments.dropFirst().first ?? "Windows.Storage"

struct AssemblyNotFound: Error {}
let context = MetadataContext(assemblyResolver: { _ in throw AssemblyNotFound() })
let assembly = try context.loadAssembly(path: #"C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.22000.0\Windows.winmd"#)

let namespaceEnumDecl = EnumDecl(identifier: namespace.replacingOccurrences(of: ".", with: "_")) {
    for typeDefinition in assembly.definedTypes.filter({ $0.namespace == namespace && $0.visibility == .public }) {
        if typeDefinition is ClassDefinition || typeDefinition is StructDefinition || typeDefinition is InterfaceDefinition {
            toClasslikeDeclListItem(typeDefinition: typeDefinition)
        }
        else if let enumDefinition = typeDefinition as? EnumDefinition {
            MemberDeclListItem(decl: toEnumDecl(enumDefinition))
        }
        // else if let delegateDefinition = typeDefinition as? DelegateDefinition {
        //     MemberDeclListItem(decl: ProtocolDecl(identifier: interfaceDefinition.name))
        // }
    }
}

func toClasslikeDeclListItem(typeDefinition: TypeDefinition) -> MemberDeclListItem {
    var members: [MemberDeclListItem] = []

    for field in typeDefinition.fields {
        guard field.visibility == .public else { continue }
        members.append(.init(decl: toPropertyDecl(field)))
    }
    
    for property in typeDefinition.properties {
        // guard property.visibility == .public else { continue }
        members.append(.init(decl: toPropertyDecl(property)))
    }

    for method in typeDefinition.methods {
        guard method.visibility == .public else { continue }
        guard !["get_", "set_", "put_", "add_", "remove_"].contains(where: { method.name.starts(with: $0) }) else { continue }
        members.append(toFuncOrInitDecl(method))
    }

    let identifier = toIdentifier(trimGenericParamCount(typeDefinition.name))
    let memberDeclBlock = MemberDeclBlock(members: MemberDeclList(members))
    switch typeDefinition {
        case is StructDefinition: 
            return MemberDeclListItem(decl: StructDecl(
                identifier: identifier,
                members: memberDeclBlock))
        case is ClassDefinition:
            return MemberDeclListItem(decl: ClassDecl(
                identifier: identifier,
                members: memberDeclBlock))
        case is InterfaceDefinition:
            return MemberDeclListItem(decl: ProtocolDecl(
                identifier: identifier,
                members: memberDeclBlock))
        default:
            fatalError("Unknown type definition")
    }
}

func toEnumDecl(_ enumDefinition: EnumDefinition) -> EnumDecl {
    EnumDecl(
        identifier: enumDefinition.name,
        inheritanceClause: TypeInheritanceClause(
            inheritedTypeCollection: InheritedTypeList([
                InheritedType(typeName: toTypeSyntax(enumDefinition.underlyingType))
            ]))) {
        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            MemberDeclListItem(decl:
                EnumCaseDecl(
                    elements: EnumCaseElementList([
                        EnumCaseElement(
                            identifier: toIdentifier(pascalToCamelCase(field.name)),
                             rawValue: InitializerClauseSyntax(value: toLiteral(field.literalValue!))
                        )
                    ])
                )
            )
        }
    }
}

func toPropertyDecl(_ field: Field) -> VariableDecl {
    return VariableDecl(
        modifiers: ModifierList(field.isStatic ? [ DeclModifier(name: .static) ] : []),
        letOrVarKeyword: .var) {
        PatternBinding(
            pattern: IdentifierPattern(
                identifier: toIdentifier(pascalToCamelCase(field.name))),
            typeAnnotation: TypeAnnotation(type: toTypeSyntax(field.type))
        )
    }
}

func toPropertyDecl(_ property: Property) -> VariableDecl {
    var accessorDecls = [AccessorDecl]()
    if property.getter !== nil {
        accessorDecls.append(AccessorDecl(accessorKind: .contextualKeyword("get")))
    }
    if property.setter !== nil {
        accessorDecls.append(AccessorDecl(accessorKind: .contextualKeyword("set",
            leadingTrivia: accessorDecls.isEmpty ? .zero : .space)))
    }

    return VariableDecl(
        letOrVarKeyword: .var) {
        PatternBinding(
            pattern: IdentifierPattern(identifier:
                toIdentifier(pascalToCamelCase(property.name))),
            typeAnnotation: TypeAnnotation(type: toTypeSyntax(property.type)),
            accessor: .accessors(AccessorBlock(
                accessors: AccessorListSyntax(accessorDecls)))
        )
    }
}

func toFuncOrInitDecl(_ method: Method) -> MemberDeclListItem {
    let parameters = (0..<method.params.count).map {
        let param = method.params[$0]
        return FunctionParameter(
            firstName: toIdentifier(param.name!),
            colon: .colon,
            type: toTypeSyntax(param.type),
            trailingComma: $0 + 1 < method.params.count ? .comma : nil
        )
    }

    let isVoid = method.returnType == context.mscorlib!.specialTypes.void.bindNonGeneric()
    let returnClause = isVoid ? nil : ReturnClause(
        returnType: toTypeSyntax(method.returnType))

    let signature = FunctionSignature(
        input: ParameterClause(
            parameterList: FunctionParameterListSyntax(parameters)
        ),
        throwsOrRethrowsKeyword: .throws,
        output: returnClause
    )

    if method is Constructor {
        return .init(decl: InitializerDecl(
            signature: signature
        ))
    }
    else {
        return .init(decl: FunctionDecl(
            modifiers: ModifierList(method.isStatic ? [ DeclModifier(name: .static) ] : []),
            identifier: toIdentifier(pascalToCamelCase(method.name)),
            signature: signature
        ))
    }
}

func toTypeSyntax(_ type: BoundType) -> TypeSyntax {
    switch type {
        case let .definition(definition):
            let genericArgs = (0..<definition.genericArgs.count).map {
                GenericArgument(
                    argumentType: toTypeSyntax(definition.genericArgs[$0]),
                    trailingComma: $0 + 1 < definition.genericArgs.count ? .comma : nil)
            }
            return toTypeSyntax(
                definition.definition,
                genericArgumentClause: genericArgs.isEmpty ? nil : GenericArgumentClause(
                    arguments: GenericArgumentList(genericArgs)))

        case let .array(element):
            return TypeSyntax(ArrayType(elementType: toTypeSyntax(element)))

        case let .genericArg(param):
            return TypeSyntax(SimpleTypeIdentifier(name: toIdentifier(param.name)))

        default:
            fatalError()
    }
}

func toTypeSyntax(_ type: TypeDefinition, genericArgumentClause: GenericArgumentClause? = nil) -> TypeSyntax {
    let name: String
    if type.namespace == "System" {
        switch type.name {
            case "Boolean": name = "Bool"
            case "Char": name = "UInt16"
            case "SByte": name = "Int8"
            case "Byte": name = "Byte"
            // [U]Int16-64 are the same
            case "IntPtr": name = "Int"
            case "UIntPtr": name = "UInt"
            case "Single": name = "Float"
            // Void is the same
            default: name = type.name
        }
    }
    else {
        name = type.name
    }

    return TypeSyntax(SimpleTypeIdentifier(
        name: toIdentifier(trimGenericParamCount(name)),
        genericArgumentClause: genericArgumentClause))
}

func toIdentifier(_ str: String) -> TokenSyntax {
    TokenKind(keyword: str) == nil ? .identifier(str) : .identifier("`\(str)`")
}

func toLiteral(_ constant: Constant) -> ExprSyntax {
    switch constant {
        case let .int8(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case let .uint8(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case let .int16(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case let .uint16(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case let .int32(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case let .uint32(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case let .int64(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case let .uint64(value): return ExprSyntax(IntegerLiteralExpr(digits: .integerLiteral(value.description)))
        case .string(_): fatalError("Not implemented: string literal")
        case .char(_): fatalError("Not implemented: char literal")
        case let .boolean(value): return ExprSyntax(BooleanLiteralExpr(booleanLiteral: value ? .trueKeyword() : .falseKeyword()))
        case .null: return ExprSyntax(NilLiteralExpr())
        default: fatalError("Unknown constant type")
    }
}

func trimGenericParamCount(_ str: String) -> String {
    guard let index = str.firstIndex(of: "`") else { return str }
    return String(str[..<index])
}

func pascalToCamelCase(_ str: String) -> String {
    // "" -> ""
    // fooBar -> fooBar
    guard str.first?.isUppercase == true else { return str }
    var lastUpperCaseIndex = str.startIndex
    while true {
        let nextIndex = str.index(after: lastUpperCaseIndex)
        guard nextIndex < str.endIndex else { break }
        guard str[nextIndex].isUppercase else { break }
        lastUpperCaseIndex = nextIndex
    }

    let firstNonUpperCaseIndex = str.index(after: lastUpperCaseIndex)

    // FOOBAR -> foobar
    if firstNonUpperCaseIndex == str.endIndex {
        return str.lowercased()
    }

    // FooBar -> fooBar
    if lastUpperCaseIndex == str.startIndex {
        return str[lastUpperCaseIndex].lowercased() + str[firstNonUpperCaseIndex...]
    }

    // UIElement -> uiElement
    return str[...lastUpperCaseIndex].lowercased() + str[firstNonUpperCaseIndex...]
}

class CustomFormat: BasicFormat {
    override func requiresLeadingSpace(_ token: TokenSyntax) -> Bool {
        switch token.tokenKind {
            case .throwsKeyword: return true
            case .leftAngle: return false
            case .rightAngle: return false
            case .rightBrace: return true
            default: return super.requiresLeadingSpace(token)
        }
    }

    override func requiresTrailingSpace(_ token: TokenSyntax) -> Bool {
        switch token.tokenKind {
            case .leftAngle: return false
            case .rightAngle: return false
            case .leftBrace: return true
            default: return super.requiresTrailingSpace(token)
        }
    }
}

print(namespaceEnumDecl.formatted(using: CustomFormat()))