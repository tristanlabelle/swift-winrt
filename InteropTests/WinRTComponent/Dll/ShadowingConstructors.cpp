#include "pch.h"

// C++/WinRT struggles with a derived class having a default constructor which delegates to a base class constructor with a parameter.
// So just stub out the exports here as we won't instantiate the classes anyways.
void * __cdecl winrt_make_WinRTComponent_ShadowingConstructorsBase() { return nullptr; }
void * __cdecl winrt_make_WinRTComponent_ShadowingConstructorsDerived() { return nullptr; }
