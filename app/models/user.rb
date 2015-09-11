class User < ActiveRecord::Base

  acts_as_token_authenticatable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :omniauthable, :omniauth_providers => [:github]

  has_many :apps, foreign_key: :creator_id

  mount_uploader :avatar, AvatarUploader

  # attr_accessor :current_password
  # # extracted from Devise
  # validates_presence_of   :email, if: :email_required?
  # validates_uniqueness_of :email, allow_blank: true
  #
  # validates_presence_of     :password, if: :password_required?
  # validates_confirmation_of :password, if: :password_required?

  # def password_required?
  #   !persisted? || !password.blank? || !password_confirmation.blank?
  # end
  #
  # # twitter doesn't provide an email, so let's not require it yet
  # def email_required?
  #   false
  # end
  #
  # def update_without_password(params, *options)
  #   result = update_attributes(params, *options)
  #   clean_up_passwords
  #   result
  # end

  def self.from_omniauth(auth)

    if old_user = find_by(email: auth.info.email, provider: 'twitter')
      old_user.update_attribute(:email, "migrated-#{old_user.email}")
    end

    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.email = auth.info.email
      user.username = auth.info.nickname
      user.remote_avatar_url = auth.info.image
      user.password = Devise.friendly_token[0,20]
    end

    if old_user
      old_user.apps.each { |app| app.creator = user; app.save }
    end

    user
  end

end
