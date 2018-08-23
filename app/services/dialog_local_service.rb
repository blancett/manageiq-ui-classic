class DialogLocalService
  NEW_DIALOG_USERS = %w(
    AvailabilityZone
    CloudNetwork
    CloudObjectStoreContainer
    CloudSubnet
    CloudTenant
    CloudVolume
    ContainerGroup
    ContainerImage
    ContainerNode
    ContainerProject
    ContainerTemplate
    ContainerVolume
    EmsCluster
    GenericObject
    Host
    InfraManager
    LoadBalancer
    MiqGroup
    NetworkRouter
    OrchestrationStack
    SecurityGroup
    Service
    ServiceAnsiblePlaybook
    ServiceAnsibleTower
    ServiceContainerTemplate
    ServiceGeneric
    ServiceOrchestration
    Storage
    Switch
    Template
    Tenant
    User
    Vm
  ).freeze

  def determine_dialog_locals_for_svc_catalog_provision(resource_action, target, finish_submit_endpoint)
    api_submit_endpoint = "/api/service_catalogs/#{target.service_template_catalog_id}/service_templates/#{target.id}"

    {
      :resource_action_id     => resource_action.id,
      :target_id              => target.id,
      :target_type            => target.kind_of?(ServiceTemplate) ? "service_template" : target.class.name.underscore,
      :dialog_id              => resource_action.dialog_id,
      :force_old_dialog_use   => false,
      :api_submit_endpoint    => api_submit_endpoint,
      :api_action             => "order",
      :finish_submit_endpoint => finish_submit_endpoint,
      :cancel_endpoint        => "/catalog/explorer",
      :open_url               => false
    }
  end

  def determine_dialog_locals_for_custom_button(obj, button_name, resource_action, display_options = {})
    dialog_locals = {:force_old_dialog_use => true}

    return dialog_locals unless NEW_DIALOG_USERS.include?(obj.class.name.demodulize)

    submit_endpoint, cancel_endpoint = determine_api_endpoints(obj, display_options)

    dialog_locals.merge!(
      :resource_action_id     => resource_action.id,
      :target_id              => obj.id,
      :target_type            => determine_target_type(obj),
      :dialog_id              => resource_action.dialog_id,
      :force_old_dialog_use   => false,
      :api_submit_endpoint    => submit_endpoint,
      :api_action             => button_name,
      :finish_submit_endpoint => cancel_endpoint,
      :cancel_endpoint        => cancel_endpoint,
      :open_url               => false
    )

    dialog_locals
  end

  private

  def determine_api_endpoints(obj, display_options = {})
    base_name = obj.class.name.demodulize
    case base_name
    when /EmsCluster/
      api_collection_name = "clusters"
      cancel_endpoint = "/ems_cluster"
    when /GenericObject/
      api_collection_name = "generic_objects"
      cancel_endpoint = if !display_options.empty? && display_options[:display_id]
                          "/service/show/#{display_options[:display_id]}?display=generic_objects"
                        else
                          "/service/explorer"
                        end
    when /InfraManager/
      api_collection_name = "providers"
      cancel_endpoint = "/ems_infra"
    when /MiqGroup/
      api_collection_name = "groups"
      cancel_endpoint = "/ops/explorer"
    when /Service/
      api_collection_name = "services"
      cancel_endpoint = "/service/explorer"
    when /Storage/
      api_collection_name = "data_stores"
      cancel_endpoint = "/storage/explorer"
    when /Switch/
      api_collection_name = "switches"
      cancel_endpoint = "/infra_networking/explorer"

    # ^ is necessary otherwise we match on ContainerTemplates
    when /^Template/
      api_collection_name = "templates"
      cancel_endpoint = "/vm_or_template/explorer"

    # ^ is necessary otherwise we match CloudTenant
    when /^Tenant/
      api_collection_name = "tenants"
      cancel_endpoint = "/ops/explorer"
    when /User/
      api_collection_name = "users"
      cancel_endpoint = "/ops/explorer"
    when /Vm/
      api_collection_name = "vms"
      cancel_endpoint = display_options[:cancel_endpoint] || "/vm_infra/explorer"
    else
      api_collection_name = base_name.underscore.pluralize
      cancel_endpoint = "/#{base_name.underscore}"
    end

    submit_endpoint = "/api/#{api_collection_name}/#{obj.id}"

    return submit_endpoint, cancel_endpoint
  end

  def determine_target_type(obj)
    case obj.class.name.demodulize
    when /^Template/
      "miq_template"
    when /InfraManager/
      "ext_management_system"
    when /^Service/
      "service"
    else
      obj.class.name.demodulize.underscore
    end
  end
end
