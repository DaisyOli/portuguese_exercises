class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :activities, dependent: :destroy
  ROLES = %w[teacher student].freeze

  validates :role, presence: true, inclusion: { in: ROLES}

  def teacher?
    role == 'teacher'
  end

  def student?
    role == 'student'
  end
end
