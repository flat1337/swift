// RUN: %swift -emit-silgen %s | FileCheck %s

class Foo {
  init() {}
  init(_ x: Foo) {}
}

class Bar: Foo {
  // CHECK-LABEL: sil @_TFC22super_init_refcounting3BarcfMS0_FT_S0_
  // CHECK:         [[SELF_VAR:%.*]] = alloc_box $Bar
  // CHECK:         [[ORIG_SELF:%.*]] = load [[SELF_VAR]]
  // CHECK-NOT:     strong_retain [[ORIG_SELF]]
  // CHECK:         [[ORIG_SELF_UP:%.*]] = upcast [[ORIG_SELF]]
  // CHECK-NOT:     strong_retain [[ORIG_SELF_UP]]
  // CHECK:         [[SUPER_INIT:%.*]] = function_ref @_TFC22super_init_refcounting3FoocfMS0_FT_S0_
  // CHECK:         [[NEW_SELF:%.*]] = apply [[SUPER_INIT]]([[ORIG_SELF_UP]])
  // CHECK:         [[NEW_SELF_DOWN:%.*]] = unchecked_ref_cast [[NEW_SELF]]
  // CHECK:         store [[NEW_SELF_DOWN]] to [[SELF_VAR]]
  init() {
    super.init()
  }
}

extension Foo {
  // CHECK-LABEL: sil @_TFC22super_init_refcounting3FoocfMS0_FT1xSi_S0_ 
  // CHECK:         [[SELF_VAR:%.*]] = alloc_box $Foo
  // CHECK:         [[ORIG_SELF:%.*]] = load [[SELF_VAR]]
  // CHECK-NOT:     strong_retain [[ORIG_SELF]]
  // CHECK:         [[SUPER_INIT:%.*]] = class_method
  // CHECK:         [[NEW_SELF:%.*]] = apply [[SUPER_INIT]]([[ORIG_SELF]])
  // CHECK:         store [[NEW_SELF]] to [[SELF_VAR]]
  convenience init(x: Int) {
    self.init()
  }
}

class Zim: Foo {
  var foo = Foo()
  // CHECK-LABEL: sil @_TFC22super_init_refcounting3ZimcfMS0_FT_S0_
  // CHECK-NOT:     strong_retain
  // CHECK-NOT:     strong_release
  // CHECK:         function_ref @_TFC22super_init_refcounting3FoocfMS0_FT_S0_
}

class Zang: Foo {
  var foo: Foo

  init() {
    foo = Foo()
    super.init()
  }
  // CHECK-LABEL: sil @_TFC22super_init_refcounting4ZangcfMS0_FT_S0_
  // CHECK-NOT:     strong_retain
  // CHECK-NOT:     strong_release
  // CHECK:         function_ref @_TFC22super_init_refcounting3FoocfMS0_FT_S0_
}

class Bad: Foo {
  // Invalid code, but it's not diagnosed till DI. We at least shouldn't
  // crash on it.
  init() {
    super.init(self)
  }
}
