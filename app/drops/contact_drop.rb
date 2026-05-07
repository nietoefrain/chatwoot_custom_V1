class ContactDrop < BaseDrop
  def name
    @obj.try(:name).try(:split).try(:map, &:capitalize).try(:join, ' ')
  end

  def email
    @obj.try(:email)
  end

  def phone_number
    @obj.try(:phone_number)
  end

  def first_name
    @obj.try(:name).try(:split).try(:first).try(:capitalize) if @obj.try(:name).try(:split).try(:size) > 1
  end

  def middle_name
    @obj.try(:middle_name)
  end

  def last_name
    return @obj.last_name if @obj.try(:last_name).present?

    @obj.try(:name).try(:split).try(:last).try(:capitalize) if @obj.try(:name).try(:split).try(:size) > 1
  end

  def location
    @obj.try(:location)
  end

  def city
    additional_attributes['city'] || location
  end

  def country
    additional_attributes['country'] || country_code
  end

  def country_code
    additional_attributes['country_code'] || @obj.try(:country_code)
  end

  def company_name
    additional_attributes['company_name']
  end

  def description
    additional_attributes['description']
  end

  def bio
    additional_attributes['bio'] || description
  end

  def biography
    bio
  end

  def additional_attributes
    attributes = @obj.try(:additional_attributes) || {}
    attributes.transform_keys(&:to_s)
  end

  def custom_attribute
    custom_attributes = @obj.try(:custom_attributes) || {}
    custom_attributes.transform_keys(&:to_s)
  end

  def custom_attributes
    custom_attribute
  end
end
