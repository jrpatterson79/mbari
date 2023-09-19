# A 10m x 10m "column" of height 100m is subjected to cyclic pressure at its top
# Assumptions:
# the boundaries are impermeable, except the top boundary
# only vertical displacement is allowed
# the atmospheric pressure sets the total stress at the top of the model
dt = 600
end_time = 864000
[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 1      
  ny = 300
  xmin = 0
  xmax = 30
  ymin = -600
  ymax = 0
  bias_y = 0.95
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
  PorousFlowDictator = dictator
  block = 0
  biot_coefficient = 0.6
  multiply_by_density = false
[]

[Variables]
  [disp_x]
    scaling = 1e-10
  []
  [disp_y]
    scaling = 1e-10
  []
  [pp]
    # scaling = 1E10
  []
[]

[ICs]
  [porepressure]
    type = FunctionIC
    variable = pp
    function = '-10000*y'#hydrostatic  # approximately correct
  []
[]

[Functions]
  [ini_stress_yy]
    type = ParsedFunction
    expression = '(25000 - 0.6*10000)*y' # remember this is effective stress
  []
  # [cyclic_porepressure]
  #   type = ParsedFunction
  #   expression = 'if(t>0,real*cos(((2*pi)/P)*t)-imag*sin(((2*pi)/P)*t),0)'
  #   symbol_names = 'real imag P'
  #   symbol_values = '5e3 2.5453e-12 86400'
  # []
  # [neg_cyclic_porepressure]
  #   type = ParsedFunction
  #   expression = '-if(t>0,real*cos(((2*pi)/P)*t)-imag*sin(((2*pi)/P)*t),0)'
  #   symbol_names = 'real imag P'
  #   symbol_values = '5e3 2.5453e-12 86400'  
  # []
  [cyclic_porepressure]
    type = ParsedFunction
    expression = 'if(t>0, amp * sin(2 * pi * (t / P)),0)'
    symbol_names = 'amp P'
    symbol_values = '5e3 86400'
  []
  [neg_cyclic_porepressure]
    type = ParsedFunction
    expression = '-if(t>0, amp * sin(2 * pi * (t / P)),0)'
    symbol_names = 'amp P'
    symbol_values = '5e3 86400'  
  []
[]

[BCs]
  # zmin is called 'back'
  # zmax is called 'front'
  # ymin is called 'bottom'
  # ymax is called 'top'
  # xmin is called 'left'
  # xmax is called 'right'
  [no_x_disp]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'left right' # because of 1-element meshing, this fixes u_x=0 everywhere
  []
  [no_y_disp_at_bottom]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = bottom # because of 1-element meshing, this fixes u_y=0 everywhere
  []
  [total_stress_at_top]
    type = FunctionNeumannBC
    variable = disp_y
    function = neg_cyclic_porepressure
    boundary = top
  []
  [pp]
    type = FunctionDirichletBC
    variable = pp
    function = cyclic_porepressure
    boundary = top
  [] 
[]

[FluidProperties]
  [the_simple_fluid]
    type = SimpleFluidProperties
    thermal_expansion = 0.0
    bulk_modulus = 2E9
    viscosity = 1E-3
    density0 = 1000.0
  []
[]

[PorousFlowBasicTHM]
  coupling_type = HydroMechanical
  displacements = 'disp_x disp_y'
  porepressure = pp
  gravity = '0 -10 0'
  fp = the_simple_fluid
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    bulk_modulus = 10.0E9 # drained bulk modulus
    poissons_ratio = 0.25
  []
  [strain]
    type = ComputeSmallStrain
    eigenstrain_names = ini_stress
  []
  [stress]
    type = ComputeLinearElasticStress
  []
  [ini_stress]
    type = ComputeEigenstrainFromInitialStress
    initial_stress = '0 0 0  0 ini_stress_yy 0  0 0 0'
    eigenstrain_name = ini_stress
  []
  [porosity]
    type = PorousFlowPorosityConst # only the initial value of this is ever used
    porosity = 0.1
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    solid_bulk_compliance = 1E-10
    fluid_bulk_modulus = 2E9
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    permeability = '1E-14 0 0   0 1E-14 0   0 0 1E-14'
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 2500.0
  []
[]

[Postprocessors]
  [p0]
    type = PointValue
    outputs = csv
    point = '0 0 0'
    variable = pp
  []
  [uz0]
    type = PointValue
    outputs = csv
    point = '0 0 0'
    variable = disp_y
  []
  [p100]
    type = PointValue
    outputs = csv
    point = '0 -100 0'
    variable = pp
  []
[]

[VectorPostprocessors]
  [depth_pp]
    type = LineValueSampler
    variable = pp
    start_point = '0 0 0'
    end_point = '0 -200 0'
    num_points = 300
    sort_by = y
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Preconditioning]
  [andy]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  # line_search = none
  solve_type = Newton
  [TimeSteppers]
    active = constant
    [constant]
      type = ConstantDT
      dt = ${dt}
    []
    [adaptive]
      type = IterationAdaptiveDT
      dt = ${dt}
      growth_factor = 1.05
    []
  []
  dtmax = 3600
  start_time = -${dt} # so postprocessors get recorded correctly at t=0
  end_time = ${end_time}
  # nl_abs_tol = 1e-8
  # nl_rel_tol = 1E-10
[]

[Outputs]
  csv = true
  file_base = './out_files/mbari'
[]
