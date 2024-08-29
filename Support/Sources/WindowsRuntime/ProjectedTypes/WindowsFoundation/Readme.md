This directory defines core types from the `Windows.Foundation` namespace (`Windows.Foundation.WindowsFoundationContract` assembly),
which are required by WinRT support code and hence cannot be code generated.

`IReference<T>` and `IReferenceArray<T>` need built-in support because we can express them through a single virtual table, independent of T, which allows implementing boxing for arbitrary primitive types, value types and delegate types.

`IPropertyValue` and `PropertyType` have nothing special and could be code generated, if it were not that the former is a base interface for `IReference<T>` and `IReferenceArray<T>`. `IPropertyValue` also refers to `DateTime`/`TimeSpan` and `Point`/`Size`/`Rect`, preventing them from being code generated.

`IStringable` has built-in support so we can automatically implement it in terms of `CustomStringConvertible`.