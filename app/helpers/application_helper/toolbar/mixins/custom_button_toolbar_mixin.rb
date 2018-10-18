module ApplicationHelper::Toolbar::Mixins::CustomButtonToolbarMixin
  APPLIES_TO_CLASS_BASE_MODELS = %w(AvailabilityZone CloudNetwork CloudObjectStoreContainer CloudSubnet CloudTenant
                                    CloudVolume ContainerGroup ContainerImage ContainerNode ContainerProject
                                    ContainerTemplate ContainerVolume EmsCluster ExtManagementSystem
                                    GenericObject GenericObjectDefinition Host LoadBalancer
                                    MiqGroup MiqTemplate NetworkRouter OrchestrationStack SecurityGroup Service
                                    ServiceTemplate Storage Switch Tenant User Vm VmOrTemplate).freeze

  def custom_button_appliable_class?(model)
    APPLIES_TO_CLASS_BASE_MODELS.include?(model)
  end

  def custom_button_class_model(applies_to_class)
    # TODO: Give a better name for this concept, including ServiceTemplate using Service
    # This should probably live in the model once this concept is defined.
    unless custom_button_appliable_class?(applies_to_class)
      raise ArgumentError, "Received: #{applies_to_class}, expected one of #{APPLIES_TO_CLASS_BASE_MODELS}"
    end

    case applies_to_class
    when "ServiceTemplate"
      Service
    when "GenericObjectDefinition"
      GenericObject
    else
      applies_to_class.constantize
    end
  end

  # Indicates, whether the user has came from providers relationship screen
  # or not
  #
  # Used to indicate if the custom buttons should be rendered
  def relationship_table_screen?
    return false if @display.nil?
    display_class = @display.camelize.singularize
    return false unless custom_button_appliable_class?(display_class)

    show_action = @lastaction == "show"
    display_model = display_class.constantize
    # method is accessed twice from a different location - from toolbar builder
    # and custom button mixin - and so controller class changes
    ctrl = self.class == ApplicationHelper::ToolbarBuilder ? controller : self
    controller_model = ctrl.class.model

    display_model != controller_model && show_action
  end
end
