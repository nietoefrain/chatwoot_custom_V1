require 'rails_helper'

describe ContactDrop do
  subject(:contact_drop) { described_class.new(contact) }

  let!(:contact) { create(:contact, custom_attributes: { car_model: 'Tesla Model S', car_year: '2022' }) }

  context 'when first name' do
    it 'returns first name' do
      contact.update!(name: 'John Doe')
      expect(subject.first_name).to eq 'John'
    end

    it('return the capitalized name') do
      contact.update!(name: 'john doe')
      expect(subject.name).to eq 'John Doe'
    end

    it('return the capitalized first name') do
      contact.update!(name: 'john doe')
      expect(subject.last_name).to eq 'Doe'
    end
  end

  context 'when last name' do
    it 'returns the last name' do
      contact.update!(name: 'John Doe')
      expect(subject.last_name).to eq 'Doe'
    end

    it 'returns the contact last name when present' do
      contact.update!(name: 'John Doe', last_name: 'Smith')
      expect(subject.last_name).to eq 'Smith'
    end

    it 'returns empty when last name not present' do
      contact.update!(name: 'John')
      expect(subject.last_name).to be_nil
    end

    it('return the capitalized last name') do
      contact.update!(name: 'john doe')
      expect(subject.last_name).to eq 'Doe'
    end
  end

  context 'when accessing custom attributes' do
    it 'returns the correct car model from custom attributes' do
      expect(contact_drop.custom_attribute['car_model']).to eq 'Tesla Model S'
    end

    it 'returns the correct car year from custom attributes' do
      expect(contact_drop.custom_attribute['car_year']).to eq '2022'
    end

    it 'returns the correct car model from custom attributes alias' do
      expect(contact_drop.custom_attributes['car_model']).to eq 'Tesla Model S'
    end

    it 'returns empty hash when there are no custom attributes' do
      contact.update!(custom_attributes: nil)
      expect(contact_drop.custom_attribute).to eq({})
    end
  end

  context 'when accessing default contact attributes' do
    it 'returns middle name' do
      contact.update!(middle_name: 'Paul')
      expect(contact_drop.middle_name).to eq 'Paul'
    end

    it 'returns location fields from contact attributes' do
      contact.update!(additional_attributes: { city: 'Santiago', country: 'Chile', country_code: 'CL' })

      expect(contact_drop.city).to eq 'Santiago'
      expect(contact_drop.country).to eq 'Chile'
      expect(contact_drop.country_code).to eq 'CL'
    end

    it 'returns company name and biography fields from additional attributes' do
      contact.update!(additional_attributes: { company_name: 'NetworkSpeed', description: 'VIP customer' })

      expect(contact_drop.company_name).to eq 'NetworkSpeed'
      expect(contact_drop.description).to eq 'VIP customer'
      expect(contact_drop.bio).to eq 'VIP customer'
      expect(contact_drop.biography).to eq 'VIP customer'
    end

    it 'returns additional attributes' do
      contact.update!(additional_attributes: { plan: 'Fiber' })
      expect(contact_drop.additional_attributes['plan']).to eq 'Fiber'
    end
  end
end
