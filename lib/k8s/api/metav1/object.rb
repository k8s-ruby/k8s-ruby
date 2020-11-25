# frozen_string_literal: true

require 'k8s/api/metav1/status'

module K8s
  module API
    module MetaV1
      # @see https://godoc.org/k8s.io/apimachinery/pkg/apis/meta/v1#OwnerReference
      class OwnerReference < Resource
        attribute :name, Types::Strict::String
        attribute :uid, Types::Strict::String
        attribute :controller, Types::Strict::Bool.optional.default(nil, shared: true)
        attribute :blockOwnerDeletion, Types::Strict::Bool.optional.default(nil, shared: true)
      end

      # @see https://godoc.org/k8s.io/apimachinery/pkg/apis/meta/v1#Initializer
      class Initializer < Struct
        attribute :name, Types::Strict::String
      end

      # @see https://godoc.org/k8s.io/apimachinery/pkg/apis/meta/v1#Initializers
      class Initializers < Struct
        attribute :pending, Initializer
        attribute :result, Status.optional.default(nil, shared: true)
      end

      # @see https://godoc.org/k8s.io/apimachinery/pkg/apis/meta/v1#ObjectMeta
      class ObjectMeta < Resource
        attribute :name, Types::Strict::String.optional.default(nil, shared: true)
        attribute :generateName, Types::Strict::String.optional.default(nil, shared: true)
        attribute :namespace, Types::Strict::String.optional.default(nil, shared: true)
        attribute :selfLink, Types::Strict::String.optional.default(nil, shared: true)
        attribute :uid, Types::Strict::String.optional.default(nil, shared: true)
        attribute :resourceVersion, Types::Strict::String.optional.default(nil, shared: true)
        attribute :generation, Types::Strict::Integer.optional.default(nil, shared: true)
        attribute :creationTimestamp, Types::DateTime.optional.default(nil, shared: true)
        attribute :deletionTimestamp, Types::DateTime.optional.default(nil, shared: true)
        attribute :deletionGracePeriodSeconds, Types::Strict::Integer.optional.default(nil, shared: true)
        attribute :labels, Types::Strict::Hash.map(Types::Strict::String, Types::Strict::String).optional.default(nil, shared: true)
        attribute :annotations, Types::Strict::Hash.map(Types::Strict::String, Types::Strict::String).optional.default(nil, shared: true)
        attribute :ownerReferences, Types::Strict::Array.of(OwnerReference).optional.default([].freeze)
        attribute :initializers, Initializers.optional.default(nil, shared: true)
        attribute :finalizers, Types::Strict::Array.of(Types::Strict::String).optional.default([].freeze)
        attribute :clusterName, Types::Strict::String.optional.default(nil, shared: true)
      end

      # common attributes shared by all object types
      class ObjectCommon < Resource
        attribute :metadata, ObjectMeta.optional.default(nil, shared: true)
      end
    end
  end
end
