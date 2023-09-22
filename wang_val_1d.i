# A 10m x 10m "column" of height 100m is subjected to cyclic pressure at its top
# Assumptions:
# the boundaries are impermeable, except the top boundary
# only vertical displacement is allowed
# the atmospheric pressure sets the total stress at the top of the model
dt = 60
end_time = 864000
[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 600    
  xmin = -200
  xmax = 0
[]

[GlobalParams]
  displacements = 'disp_x'
  PorousFlowDictator = dictator
  block = 0
  biot_coefficient = 0.6
  multiply_by_density = false
[]

[Variables]
  [disp_x]
  []
  [pp]
    scaling = 1E10
  []
[]

[ICs]
  [porepressure]
    type = FunctionIC
    variable = pp
    function = '-10000*x'#hydrostatic  # approximately correct
  []
[]

[Functions]
  [ini_stress_xx]
    type = ParsedFunction
    expression = '(25000 - 0.6*10000)*x' # remember this is effective stress
  []
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
  [no_x_disp_at_bottom]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = left # because of 1-element meshing, this fixes u_y=0 everywhere
  []
  [total_stress_at_top]
    type = FunctionNeumannBC
    variable = disp_x
    function = neg_cyclic_porepressure
    boundary = right
  []
  [pp]
    type = FunctionDirichletBC
    variable = pp
    function = cyclic_porepressure
    boundary = right
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
  displacements = 'disp_x'
  porepressure = pp
  gravity = '-10 0 0'
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
    initial_stress = 'ini_stress_xx 0 0  0 0 0  0 0 0'
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
    variable = disp_x
  []
  [p100]
    type = PointValue
    outputs = csv
    point = '-100 0 0'
    variable = pp
  []
[]

[VectorPostprocessors]
  [depth_pp]
    type = LineValueSampler
    variable = pp
    start_point = '0 0 0'
    end_point = '-200 0 0'
    num_points = 300
    sort_by = x
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
  solve_type = Newton
  [TimeSteppers]
    active = adaptive
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
